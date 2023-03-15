# DynamoDB Data Importer

A tool to import DynamoDB using [BatchWriteItem](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchWriteItem.html) and bypass the 25-item-per-operation limit. Before proceeding further, please consider [importing from S3](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/S3DataImport.HowItWorks.html) if the target table does not exist yet; it's cheaper and more efficient.

![Demo](./docs/assets/images/demo.gif)

## Usage

```sh
ddmimp -t dynamodb-table-name path/to/the/json/line/data.jsonl
```

> **_NOTE:_** Mind your table schema, item size, and traffic cost.

## Installation

To make `ddbimp` available in your system, you can run the following command.

```sh
go install <THIS_REPO_URL_WITHOUT_PROTOCAL_PREFIX>@latest
```
