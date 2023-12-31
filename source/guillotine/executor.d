/** 
 * Executor service for task submission and tracking
 */
module guillotine.executor;

import guillotine.future : Future;
import guillotine.value;
import guillotine.result : Result;
import guillotine.provider;
import std.traits : isFunction, isDelegate, FunctionTypeOf, ReturnType, arity;
import std.traits : isAssignable;
import std.functional : toDelegate;

// TODO: Document
private bool isSupportedReturn(alias FuncSymbol)()
{
    return __traits(isSame, ReturnType!(FuncSymbol), int) ||
           __traits(isSame, ReturnType!(FuncSymbol), bool) ||
           isAssignable!(Object, ReturnType!(FuncSymbol)) ||
           __traits(isSame, ReturnType!(FuncSymbol), float) ||
           __traits(isSame, ReturnType!(FuncSymbol), void);
}

// TODO: Document
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
    private Value delegate() func;

    /** 
     * Constructs a new `FutureTask` with the
     * provided future and function to run
     *
     * Params:
     *   future = the `Future` to associate with
     *   func = the function to run
     */
    this(Future future, Value delegate() func)
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
        // Return value (in non-error case)
        Value retVal;

        // The exception (in error case)
        Exception errVal;

        try
        {
            // Set the future's state to running now
            import guillotine.future : State;
            future.state = State.RUNNING;

            // Run the function and obtain its return value (on success)
            retVal = func();
        }
        catch(Exception e)
        {
            errVal = e;
        }

        if(errVal is null)
        {
            future.complete(Result(retVal));
        }
        else
        {
            future.error(errVal);
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
private template WorkerFunction(alias FuncIn)
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
        else static if(isAssignable!(Object, funcInReturn))
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
public alias DefaultProvider = Sequential;

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

    /** 
     * Constructs a new `Executor` wuth the
     * default provider
     */
    this()
    {
        this(new DefaultProvider());
    }

    /** 
     * Submits the provided function as a task
     * and returns a handle to it in the form
     * of a future
     *
     * Returns: the task's `Future`
     */
    public Future submitTask(alias Symbol)()
    if ((isFunction!(Symbol) || isDelegate!(Symbol)) && isSupportedFunction!(Symbol))
    {
        FutureTask task;

        Value delegate() ptr;
        alias func = Symbol;

        static if(isDelegate!(Symbol))
        {
            ptr = &WorkerFunction!(func).workerFunc;
        }
        else
        {
            ptr = toDelegate(&WorkerFunction!(func).workerFunc);
        }

        version(unittest)
        {
            import std.stdio;
            writeln("Generated worker function: ", ptr);
        }

        // Create the Future
        Future future = new Future();

        // Create the Future task
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
    assert(res1.getValue().value.integer == 69);

    // Stops the internal task runner thread
    provider.stop();
}

version(unittest)
{
    private int hi()
    {
        writeln("Let's go hi()!");

        // Pretend to do some work
        Thread.sleep(dur!("seconds")(2));

        return 69;
    }

    private float hiFloat()
    {
        writeln("Let's go hiFloat()!");

        // Pretend to do some work
        Thread.sleep(dur!("seconds")(10));
        
        return 69.420;
    }

    private void hiVoid()
    {
        writeln("Let's go hiVoid()!");

        // Pretend to do some work
        Thread.sleep(dur!("seconds")(10));
    }
}