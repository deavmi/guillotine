module guillotine.texecutor;

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

private class FutureTask : Task
{
    // Related future for this task
    private Future future;

    // Function to call
    private Value function() func;


    this(Future future, Value function() func)
    {
        this.future = future;
        this.func = func;
    }

   
    public void run()
    {
        // TODO: May this boitjie throw functions?
        // ... if it can we could get errors and
        // ... set the Future below correctly
        bool hasError;
        
        Value retVal;

        try
        {
            retVal = func();
        }
        catch(Exception e)
        {
            hasError = true;
        }

        // TODO: Store retVal into it
        if(!hasError)
        {
            future.complete(Result(retVal));
        }
        else
        {
            future.error();
        }

        // TODO: wake future slpeers
        
        
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
        // TODO: Need more constructor


        // Value value = Value(FuncIn());

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