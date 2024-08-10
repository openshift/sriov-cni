- [CNI Log](#cni-log)
- [Usage](#usage)
  - [Importing cni-log](#importing-cni-log)
  - [Customizing the logging prefix/header](#customizing-the-logging-prefixheader)
  - [Public Types \& Functions](#public-types--functions)
    - [Types](#types)
      - [Level](#level)
      - [Prefixer](#prefixer)
      - [LogOptions](#logoptions)
    - [Public setup functions](#public-setup-functions)
      - [SetLogLevel](#setloglevel)
      - [GetLogLevel](#getloglevel)
      - [StringToLevel](#stringtolevel)
      - [String](#string)
      - [SetLogStderr](#setlogstderr)
      - [SetLogOptions](#setlogoptions)
      - [SetLogFile](#setlogfile)
      - [SetOutput](#setoutput)
      - [SetPrefixer](#setprefixer)
      - [SetDefaultPrefixer](#setdefaultprefixer)
    - [Logging functions](#logging-functions)
  - [Default values](#default-values)

## CNI Log

The purpose of this package is to perform logging for CNI projects in NPWG. Cni-log provides general logging functionality for Container Network Interfaces (CNI). Messages can be logged to a log file and/or to standard error.  

## Usage

The package can function out of the box as most of its configurations have [default values](#default-values). Just call any of the [logging functions](#logging-functions) to start logging. To further define log settings such as the log file path, the log level, as well as the lumberjack logger object, continue on to the [public functions below](#public-types--functions).

### Importing cni-log

Import cni-log in your go file:

```go
import (
    ...
    "github.com/k8snetworkplumbingwg/cni-log"
    ...
)
```

Then perform a `go mod tidy` to download the package.

Please ensure that the log file is properly specified; otherwise, no information will be printed to the console. In the event that the log file is not configured correctly, relevant error messages will be printed to the console.

```go
    ...
    logging.SetLogFile("samplelog.log")
    ...
```

### Customizing the logging prefix/header

CNI-log allows users to modify the logging prefix/header. The default prefix is in the following format:

```
yyyy-mm-ddTHH:MM:SSZ [<log level>] ...
```

E.g.

```
2022-10-11T13:09:57Z [info] This is a log message with INFO log level
```

To change the prefix used by cni-log, you will need to provide the implementation of how the prefix string would be built. To do so you will need to create an object of type [``Prefixer``](#prefixer). ``Prefixer`` is an interface with one function:

```go
CreatePrefix(Level) string
```

Implement the above function with the code that would build the prefix string. In order for CNI-Log to use your custom prefix you will then need to pass in your custom prefix object using the [``SetPrefixer``](#setprefixer) function.

Below is sample code on how to build a custom prefix:

```go
package main
import (
  ...
  logging "github.com/k8snetworkplumbingwg/cni-log"
  ...
)

// custom prefix type
type customPrefix struct {
  prefixFormat string
  timeFormat   string
  currentFile  string
}

func main() {
  // cni-log configuration
  logging.SetLogFile("samplelog.log")
  logging.SetLogLevel(logging.DebugLevel)
  logging.SetLogStderr(true)

  // Creating the custom prefix object
  prefix := &customPrefix{
    prefixFormat: "%s | %s | %s | ",
    timeFormat:   time.RFC850,
    currentFile:  "main.go",
  }
  logging.SetPrefixer(prefix) // Tell cni-log to use your custom prefix object

  // Log messages
  logging.Infof("Info log message")
  logging.Warningf("Warning log message")
}

// Implement the CreatePrefix function using your custom prefix object. This function will be called by CNI-Log
// to build the prefix string. 
func (p *customPrefix) CreatePrefix(loggingLevel logging.Level) string {
  currentTime := time.Now()
  return fmt.Sprintf(p.prefixFormat, currentTime.Format(p.timeFormat), p.currentFile, loggingLevel)
}
```

### Public Types & Functions

#### Types

##### Level

```go
// Level type
type Level int
```

Defines the type that will represent the different log levels

##### Prefixer

```go
type Prefixer interface {
  CreatePrefix(Level) string
}
```

Defines an interface that contains one function: ``CreatePrefix(Level) string``. Implementing this function allows you to build your own custom prefix.

##### LogOptions

```go
// LogOptions defines the configuration of the lumberjack logger
type LogOptions struct {
  MaxAge     *int  `json:"maxAge,omitempty"`
  MaxSize    *int  `json:"maxSize,omitempty"`
  MaxBackups *int  `json:"maxBackups,omitempty"`
  Compress   *bool `json:"compress,omitempty"`
}
```

For further details of each field, see the [lumberjack documentation](https://github.com/natefinch/lumberjack).

To view the default values of each field, go to the "[Default values](#default-values)" section

#### Public setup functions

##### SetLogLevel

```go
func SetLogLevel(level Level)
```

Sets the log level. The valid log levels are:
| int | string | Level |
| --- | --- | --- |
| 1 | panic | PanicLevel |
| 2 | error | ErrorLevel |
| 3 | warning | WarningLevel |
| 4 | info | InfoLevel |
| 5 | debug | DebugLevel |

The log levels above are in ascending order of verbosity. For example, setting the log level to InfoLevel would mean "panic", "error", warning", and "info" messages will get logged while "debug" will not.

##### GetLogLevel

```go
func GetLogLevel() Level
```

Returns the current log level

##### StringToLevel

```go
func StringToLevel(level string) Level
```

Returns the Level equivalent of a string. See SetLogLevel for valid levels.

##### String

```go
func (l Level) String() string
```

Returns the string representation of a log level

##### SetLogOptions

```go
func SetLogOptions(options *LogOptions)
```

Configures the lumberjack object based on the lumberjack configuration data set in the ``logOptions`` object (see ``logOptions`` struct above).

##### SetLogFile

```go
func SetLogFile(filename string)
```

Configures where logs will be written to. If an empty filepath is used, disable logging to file.
No change will occur if an invalid filepath (e.g. insufficient permissions) or a symbolic link is passed into the
function.

##### SetLogStderr

```go
func SetLogStderr(enable bool)
```

This function allows you to enable/disable logging to standard error.

> **NOTE:** For logging, a valid log file must be set or logging to stderr must be enabled.

##### SetOutput

```go
func SetOutput(out io.Writer)
```

Set custom output. Calling this function will discard any previously set LogOptions.

##### SetPrefixer

```go
func SetPrefixer(p Prefixer)
```

This function allows you to override the default logging prefix with a custom prefix.

##### SetDefaultPrefixer

```go
func SetDefaultPrefixer()
```

This function allows you to return to the default logging prefix.

#### Logging functions

The logger comes with 2 sets of logging functions.

`Printf` style functions:
```go
// Errorf prints logging if logging level >= error
func Errorf(format string, a ...interface{}) error 

// Warningf prints logging if logging level >= warning
func Warningf(format string, a ...interface{})

// Infof prints logging if logging level >= info
func Infof(format string, a ...interface{})

// Debugf prints logging if logging level >= debug
func Debugf(format string, a ...interface{})
```

Structured (crio logging style) functions:
```go
// PanicStructured provides structured logging for log level >= panic.
func PanicStructured(msg string, args ...interface{})

// ErrorStructured provides structured logging for log level >= error.
func ErrorStructured(msg string, args ...interface{}) error

// WarningStructured provides structured logging for log level >= warning.
func WarningStructured(msg string, args ...interface{})

// InfoStructured provides structured logging for log level >= info.
func InfoStructured(msg string, args ...interface{})

// DebugStructured provides structured logging for log level >= debug.
func DebugStructured(msg string, args ...interface{})
```

### Default values

| Variable | Default Value |
| ---     | ---           |
| logLevel | info |
| logToStderr | true |
| Logger.Filename | "" |
| LogOptions.MaxSize | 100 |
| LogOptions.MaxAge | 5 |
| LogOptions.MaxBackups | 5 |
| LogOptions.Compress | true |
