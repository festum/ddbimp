package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/cenkalti/backoff"
	"github.com/pterm/pterm"
)

var (
	_region    = flag.String("r", "eu-central-1", "AWS region")
	_tableName = flag.String("t", "", "Existing DynamoDB table")

	_parallelAmount = flag.Int("amount", 10, "Amount in parallel")
)

func main() {
	flag.Parse()

	filePath := flag.Arg(0)
	if filePath == "" {
		fmt.Printf("Usage:\n\t%s -t tableName \"path/to/file.json\"\n", os.Args[0])
		return
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(), func(o *config.LoadOptions) error {
		o.Region = *_region
		o.RetryMaxAttempts = 0
		return nil
	})
	if err != nil {
		log.Fatal("failed to load aws config:", err)
	}

	parallelBatchImport(cfg, filePath)
}

func parallelBatchImport(cfg aws.Config, filePath string) {

	file, err := os.Open(filePath)
	if err != nil {
		log.Fatal("failed to open", filePath)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)

	batchCount := 0
	startTime := time.Now()

	var wg sync.WaitGroup
	var totalItems, unprocessedItems int

	client := dynamodb.NewFromConfig(cfg)
	var p *pterm.ProgressbarPrinter

	if _, err := client.DescribeTable(context.Background(), &dynamodb.DescribeTableInput{TableName: _tableName}); err != nil {
		log.Fatalln("Check table failed:", err)
		return
	}

	for {
		requests := packing(scanner, &totalItems)
		if requests == nil {
			break
		}

		wg.Add(1)
		go func() {
			if batchCount%*_parallelAmount == 0 {
				time.Sleep(time.Duration(*_parallelAmount*100) * time.Millisecond)
			}

			unprocessedItemsInBatch, err := batchWrite(client, requests)
			unprocessedItems += unprocessedItemsInBatch
			if err != nil {
				log.Println("batch write failed:", err)
			}
			for p == nil {
				time.Sleep(100 * time.Millisecond)
			}
			p.Increment()
			wg.Done()
		}()
		batchCount++
	}
	time.Sleep(400 * time.Millisecond) // Waiting for rendering initiate
	p, _ = pterm.DefaultProgressbar.WithTotal(batchCount).WithTitle("Processing batch...").Start()
	wg.Wait()

	pterm.Success.Println(fmt.Sprintf("All batches finished, updated %v records in %v seconds ", totalItems-unprocessedItems, time.Since(startTime).Seconds()))
}

func packing(scanner *bufio.Scanner, totalItems *int) (requests []types.WriteRequest) {
	const batchSize = 25
	for i := 0; i < batchSize && scanner.Scan(); i, *totalItems = i+1, *totalItems+1 {
		record := map[string]string{}
		if jsonErr := json.Unmarshal(scanner.Bytes(), &record); jsonErr != nil {
			log.Println("failed to unmarshal", scanner.Text())
			continue
		}

		item := map[string]types.AttributeValue{}
		for k, v := range record {
			item[k] = &types.AttributeValueMemberS{Value: v}
		}

		requests = append(requests, types.WriteRequest{
			PutRequest: &types.PutRequest{
				Item: item,
			},
		})
	}
	return
}

func batchWrite(client *dynamodb.Client, requests []types.WriteRequest) (unprocessedItems int, fatalError error) {
	backoff.Retry(func() error {
		op, err := client.BatchWriteItem(context.Background(), &dynamodb.BatchWriteItemInput{
			RequestItems: map[string][]types.WriteRequest{
				*_tableName: requests,
			},
		})
		if op != nil && op.UnprocessedItems != nil {
			unprocessedItems += len(op.UnprocessedItems)
		}
		if err != nil && !strings.Contains(err.Error(), "retry quota exceeded") {
			fatalError = err
			return nil
		}
		return err
	}, backoff.NewExponentialBackOff())
	return unprocessedItems, fatalError
}
