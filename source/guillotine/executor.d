module guillotine.executor;

import guillotine.future : Future;
import guillotine.value;
import guillotine.result : Result;
import guillotine.provider;
import std.traits : isFunction, FunctionTypeOf, ReturnType, arity;


private bool isSupportedReturn(alias FuncSymbol)()
{
    return __traits(isSame, ReturnType!(FuncSymbol), int) ||
           __traits(isSame, ReturnType!(FuncSymbol), bool) ||
           __traits(isSame, ReturnType!(FuncSymbol), Object) ||
           __traits(isSame, ReturnType!(FuncSymbol), float) ||
           __traits(isSame, ReturnType!(FuncSymbol), void);
}

private bool isSupportedFunction(alias FuncSymbol)()
{
    // Arity must be 0
    return arity!(FuncSymbol) == 0 && isSupportedReturn!(FuncSymbol);
}

/** 
 * This wraps a provided function
 * and `Future` toghether in a way
 * such that one can submit this
 * to a provider as a kind-of `Task`
 * which when completed will wake up
 * those waiting on the `Future`
 */
private class FutureTask : Task
{
    /** 
     * Related future for this task
     */
    private Future future;

    /** 
     * Function to call
     */
    private Value function() func;

    /** 
     * Constructs a new `FutureTask` with the
     * provided future and function to run
     *
     * Params:
     *   future = the `Future` to associate with
     *   func = the function to run
     */
    this(Future future, Value function() func)
    {
        this.future = future;
        this.func = func;
    }

    /** 
     * The wrapper task that will run and extract
     * any values/errors and report these back
     * to the associated `Future`
     */
    public void run()
    {
        // If there waas an error in calling `func()`
        bool hasError;
        
        // Return value (in non-error case)
        Value retVal;

        try
        {
            retVal = func();
        }
        catch(Exception e)
        {
            hasError = true;
        }

        if(!hasError)
        {
            future.complete(Result(retVal));
        }
        else
        {
            future.error();
        }
    }
}

/** 
 * Generates a `Value`-returning function with
 * a 0 parameter arity based on an input symbol
 * of an existing function which has 0 arity
 * and return a supported type
 *
 * Params:
 *   FuncIn = The name of the function to wrap
 */
template WorkerFunction(alias FuncIn)
{
    /** 
     * Generated "wrapper" function
     *
     * Returns: the `Value` of the result
     */
    Value workerFunc()
    {
        alias funcInReturn = ReturnType!(FuncIn);

        Value value;
        ValueUnion valUnion;

        static if(__traits(isSame, funcInReturn, int))
        {
            valUnion.integer = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, uint))
        {
            valUnion.uinteger = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, float))
        {
            valUnion.floating = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, bool))
        {
            valUnion.boolean = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, string))
        {
            valUnion.str = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, Object))
        {
            valUnion.object = FuncIn();
        }
        else static if(__traits(isSame, funcInReturn, void))
        {
            // With no return type you just call it
            FuncIn();

            // We create an emoty struct
            valUnion.none = Empty();
        }
        
        
        

        value.value = valUnion;
        return value;
    }
}

import guillotine.providers.sequential : Sequential;

/** 
 * The default `Provider`
 */
alias DefaultProvider = Sequential;

/** 
 * Provides a task submission service upon
 * which tasks can be submitted and a `Future`
 * is returned as handle to that submitted task.
 *
 * The underlying scheduling/threading mechanism
 * is provided in the form of a `Provider`
 */
public class Executor
{
    /** 
     * Underlying thread provider
     * whereby the tasks will be
     * pushed into for running
     */
    private Provider provider;

    /** 
     * Constructs a new `Executor` with the given
     * provider which provides us with some sort
     * of underlying thread execution mechanism
     * where the tasks will actually be executed
     *
     * Params:
     *   provider = the `Provider` to use
     */
    this(Provider provider)
    {
        this.provider = provider;
    }

    this()
    {
        this(new DefaultProvider());
    }


    

    public Future submitTask(alias Symbol)()
    if (isFunction!(Symbol) && isSupportedFunction!(Symbol))
    {
        FutureTask task;

        Value function() ptr;
        alias func = Symbol;
        

        ptr = &WorkerFunction!(func).workerFunc;

        version(unittest)
        {
            import std.stdio;
            writeln("Generated worker function: ", ptr);
        }

        // Create the Future
        Future future = new Future();

        // Create the FUture task
        task = new FutureTask(future, ptr);

        // Submit the task
        provider.consumeTask(task);

        version(unittest)
        {
            writeln("Just submitted future task: ", future);
        }

        return future;
    }
}

version(unittest)
{
    import std.stdio : writeln;
    import core.thread : Thread, dur;
}

/**
 * Tests the submission of three tasks using
 * the `Sequential` provider and with the first
 * two tasks having values to return and the last
 * having nothing
 */
unittest
{
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
}

version(unittest)
{
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
}