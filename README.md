![](branding/banner.png)

guillotine
==========

[![D](https://github.com/deavmi/guillotine/actions/workflows/d.yml/badge.svg)](https://github.com/deavmi/guillotine/actions/workflows/d.yml) ![DUB](https://img.shields.io/dub/v/guillotine?color=%23c10000ff%20&style=flat-square) ![DUB](https://img.shields.io/dub/dt/guillotine?style=flat-square) ![DUB](https://img.shields.io/dub/l/guillotine?style=flat-square) [![Coverage Status](https://coveralls.io/repos/github/deavmi/guillotine/badge.svg?branch=master)](https://coveralls.io/github/deavmi/guillotine?branch=master)

Executor framework with future-based task submission and pluggable thread execution engines

## Usage

You can add this to your project easily by using:

```bash
dub add guillotine
```

## API

The full API is documented at [here](https://guillotine.dpldocs.info/).

## Example

Tests the submission of three tasks using the `Sequential` provider and with the first two tasks having values to return and the last having nothing.

```d
import guillotine.providers.sequential;
import guillotine.executor;
import guillotine.future;
import guillotine.result;
import guillotine.provider;

Provider provider = new Sequential();

// Start the provider so it can execute
// submitted tasks
provider.start();

// Create an executor with this provider
Executor t = new Executor(provider);


// Submit a few tasks
Future fut1 = t.submitTask!(hi);
Future fut2 = t.submitTask!(hiFloat);
Future fut3 = t.submitTask!(hiVoid);

// Await on the first task
writeln("Fut1 waiting...");
Result res1 = fut1.await();
writeln("Fut1 done with: '", res1.getValue().value.integer, "'");

// Stops the internal task runner thread
provider.stop();
```

Let's also define those functions we are using:

```
public int hi()
{
    writeln("Let's go hi()!");

    // Pretend to do some work
    Thread.sleep(dur!("seconds")(2));

    return 69;
}

public float hiFloat()
{
    writeln("Let's go hiFloat()!");

    // Pretend to do some work
    Thread.sleep(dur!("seconds")(10));
    
    return 69.420;
}

public void hiVoid()
{
    writeln("Let's go hiVoid()!");

    // Pretend to do some work
    Thread.sleep(dur!("seconds")(10));
}
```
