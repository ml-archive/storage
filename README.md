# Storage
[![Language](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Build Status](https://travis-ci.org/nodes-vapor/storage.svg?branch=master)](https://travis-ci.org/nodes-vapor/storage)
[![codecov](https://codecov.io/gh/nodes-vapor/storage/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/storage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/storage/master/LICENSE)

A package to ease the use of multiple storage and CDN services.

##### Table of Contents
* [Getting started](#getting-started-)
* [Upload a file](#upload-a-file-)
  * [Base 64 and data URI](#base-64-and-data-uri-)
* [Download a file](#download-a-file-)
* [Delete a file](#delete-a-file-)
* [Configuration](#configuration-)
  * [Network driver](#network-driver-)
  * [Upload path](#upload-path-)

## Integration
Update your `Package.swift` file.
```swift
.Package(url: "https://github.com/nodes-vapor/storage", majorVersion: 0)
```

## Getting started 🚀
`Storage` offers a [Provider](https://vapor.github.io/documentation/guide/provider.html) and does all configuration through JSON files.

```swift
import Storage
try drop.addProvider(StorageProvider.self)
```

Now, create a JSON file named `Config/storage.json` with the following contents:

```json
{
  "driver": "s3",
  "accessKey": "$YOUR_AWS_ACCESS_KEY",
  "secretKey": "$YOUR_AWS_SECRET_KEY",
  "template": "$folder/$file"
}
```
Learn about [these fields and more](#configuration-).

## Upload a file 🌐
There are a few different interfaces for uploading a file, the simplest being the following:
```swift
Storage.upload(
  bytes: [UInt8],
  fileName: String?,
  fileExtension: String?,
  mime: String?,
  folder: String
) throws -> String
```
The aforementioned function will attempt to upload the file using your [selected driver and template](#configuration-) and will return a `String` representing the location of the file.

If you want to upload an image named `profile.png` your call site would look like:
```swift
let path = try Storage.upload(bytes: bytes, fileName: "profile", fileExtension: "png")
print(path) //prints `images/profile.png`
```

#### Base64 and data URI 📡
Is your file a base64 or data URI? No problem!
```swift
Storage.upload(base64: String, //...)
Storage.upload(dataURI: String, //...)
```

## Download a file ✅
To download a file that was previously uploaded you simply use the generated path.
```swift
//download image as `Foundation.Data`
let data = try Storage.get("images/profile.png")
```

## Delete a file ❌
Deleting a file using this package isn't the recommended way to handle removal, but is still possible.
```swift
try Storage.delete("images/profile.png")
```
## Configuration ⚙
`Storage` has a variety of configurable options.
#### Network driver 🔨
The network driver is the module responsible for interacting with your 3rd party service. The default, and currently the only, driver is `s3`.
```json
{
  "driver": "s3",
  "accessKey": "$YOUR_AWS_ACCESS_KEY",
  "secretKey": "$YOUR_AWS_SECRET_KEY"
}
```
The `driver` key is optional and will default to `aws`. `accessKey` and `secretKey` are both required by the AWS driver.

#### Upload path 🛣
A times, you may need to upload files to a different scheme than `folder/file.ext`. You can achieve this by adding the `"template"` field to your `Config/storage.json`. If the field is omitted it will default to `$folder/$file`.

The following template will upload `profile.png` from the folder `images` to `myapp/images/profile.png`
```json
"template": "myapp/$folder/$file"
```

##### Aliases
There are a few aliases that will be replaced by the real metadata of the file at the time of upload. They are:

* `$file`: The file's name and extension.
* `$fileName`: The file's name.
* `$fileExtension`: The file's extension.
* `$folder`: The provided folder
* `$mimeFolder`: A folder generated according to the file's mime.

## 🏆 Credits
This package is developed and maintained by the Vapor team at [Nodes](https://www.nodes.dk).

## 📄 License
This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)