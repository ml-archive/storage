# Storage 🗄
[![Swift Version](https://img.shields.io/badge/Swift-3.1-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-2-F6CBCA.svg)](http://vapor.codes)
[![Linux Build Status](https://img.shields.io/circleci/project/github/nodes-vapor/storage.svg?label=Linux)](https://circleci.com/gh/nodes-vapor/storage)
[![macOS Build Status](https://img.shields.io/travis/nodes-vapor/storage.svg?label=macOS)](https://travis-ci.org/nodes-vapor/storage)
[![codebeat badge](https://codebeat.co/badges/52c2f960-625c-4a63-ae63-52a24d747da1)](https://codebeat.co/projects/github-com-nodes-vapor-storage)
[![codecov](https://codecov.io/gh/nodes-vapor/storage/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/storage)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/storage)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/storage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/storage/master/LICENSE)

A package to ease the use of multiple storage and CDN services.


##### Table of Contents
* [Getting started](#getting-started-)
* [Upload a file](#upload-a-file-)
  * [Base 64 and data URI](#base-64-and-data-uri-)
* [Download a file](#download-a-file-)
* [Get CDN path](#get-cdn-path)
* [Delete a file](#delete-a-file-)
* [Configuration](#configuration-)
  * [Network driver](#network-driver-)
  * [Upload path](#upload-path-)


## 📦 Installation

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
  "bucket": "$AWS_S3_BUCKET",
  "accessKey": "$AWS_ACCESS_KEY",
  "secretKey": "$AWS_SECRET_KEY",
  "host": "s3.amazonaws.com",
  "cdnUrl": "$CDN_BASE_URL"
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
let path = try Storage.upload(bytes: bytes, fileName: "profile.png")
print(path) //prints `/profile.png`
```

#### Base64 and data URI 📡
Is your file a base64 or data URI? No problem!
```swift
Storage.upload(base64: "SGVsbG8sIFdvcmxkIQ==", fileName: "base64.txt")
Storage.upload(dataURI: "data:,Hello%2C%20World!", fileName: "data-uri.txt")
```

#### Remote resources 
Download an asset from a URL and then reupload it to your storage server.
```swift
Storage.upload(url: "http://mysite.com/myimage.png", fileName: "profile.png")
```


## Download a file ✅

To download a file that was previously uploaded you simply use the generated path.
```swift
//download image as `Foundation.Data`
let data = try Storage.get("/images/profile.png")
```


## Get CDN path

Here is how you generate the CDN path to a given asset.
```swift
let cdnPath = Storage.getCDNPath(for: path)
```

If your CDN path is more involved than `cdnUrl` + `path`, you can build out Storage's optional completionhandler to override the default functionality.

```swift
Storage.cdnPathBuilder = { baseURL, path in
    let joinedPath = (baseURL + path)
    return joinedPath.replacingOccurrences(of: "/images/original/", with: "/image/")
}
```


## Delete a file ❌

Deleting a file using this package isn't the recommended way to handle removal, but is still possible.
```swift
try Storage.delete("/images/profile.png")
```


## Configuration ⚙

`Storage` has a variety of configurable options.

#### Network driver 🔨
The network driver is the module responsible for interacting with your 3rd party service. The default, and currently the only, driver is `s3`.
```json
{
  "driver": "s3",
  "bucket": "$AWS_S3_BUCKET",
  "accessKey": "$AWS_ACCESS_KEY",
  "secretKey": "$AWS_SECRET_KEY",
  "host": "s3.amazonaws.com",
  "cdnUrl": "$CDN_BASE_URL"
  "region": "eu-west-1"
}
```
The `driver` key is optional and will default to `s3`. `accessKey` and `secretKey` are both required by the S3 driver, while `host`, `bucket` and `region` are all optional. `region` will default to `eu-west-1` and `host` will default to `s3.amazonaws.com` if not provided. The above example uses the environment variables as provided by [Vapor Cloud](https://vapor.cloud/), but you can change this to use hardcoded values although this is not recommended. Another option is to use "fallback values" which can be achieved by using the `:` notion. For example `$AWS_S3_BUCKET:my-bucket` will fallback to `my-bucket` when the `AWS_S3_BUCKET` environment variable is not present.

#### Upload path 🛣
A times, you may need to upload files to a different scheme than `/file.ext`. You can achieve this by adding the `"template"` field to your `Config/storage.json`. If the field is omitted it will default to `/#file`.

The following template will upload `profile.png` from the folder `images` to `/myapp/images/profile.png`
```json
"template": "/myapp/#folder/#file"
```

##### Aliases
Aliases are special keys in your template that will be replaced with dynamic information at the time of upload.

 *Note: if you use an alias and the information wasn't provided at the file upload's callsite, Storage will throw a `missingX`/`malformedX` error.*

`#file`: The file's name and extension.

```
File: "test.png"
Returns: test.png
```

---

`#fileName`: The file's name.

```
File: "test.png"
Returns: test
```

---

`#fileExtension`: The file's extension.

```
File: "test.png"
Returns: png
```

---

`#folder`: The provided folder.

```
File: "uploads/test.png"
Returns: uploads
```

---

`#mime`: The file's content type.

```
File: "test.png"
Returns: image/png
```

---

`#mimeFolder`: A folder generated according to the file's mime.

This alias will check the file's mime and if it's an image, it will return `images/original` else it will return `data`

```
File: "test.png"
Returns: images/original
```

---

`#day`: The current day.

```
File: "test.png"
Date: 12/12/2012
Returns: 12
```

---

`#month`: The current month.

```
File: "test.png"
Date: 12/12/2012
Returns: 12
```

---

`#year`: The current year.

```
File: "test.png"
Date: 12/12/2012
Returns: 2012
```

---

`#timestamp`: The time of upload.

```
File: "test.png"
Time: 17:05:00
Returns: 17:05:00
```

---

`#uuid`: A generated UUID.

 ```
File: "test.png"
Returns: 123e4567-e89b-12d3-a456-426655440000
```

---
## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).
The package owner for this project is [Brett](https://github.com/brettRToomey).


## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
