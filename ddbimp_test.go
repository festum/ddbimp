package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPacking(t *testing.T) {
	file, err := ioutil.TempFile("/tmp", "ddbimp_test_")
	assert.Nil(t, err)
	defer os.Remove(file.Name())
	defer file.Close()

	for i := 0; i < 30; i++ {
		_, err = file.WriteString(fmt.Sprintf("{\"pk\":\"foo%v\",\"val1\":\"bar%v\"}\n", i, i))
		assert.Nil(t, err)
	}
	totalItems := 0

	file.Seek(0, 0)
	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)

	req := packing(scanner, &totalItems)
	assert.NotNil(t, req)
	assert.Equal(t, 25, totalItems)
	assert.Equal(t, 25, len(req))

	req = packing(scanner, &totalItems)
	assert.Equal(t, 30, totalItems)
	assert.Equal(t, 5, len(req))
}
