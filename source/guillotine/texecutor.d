module guillotine.texecutor;

import guillotine.executor : Executor;
import guillotine.future : Future;

import std.traits : ReturnType;
private bool isSupportedReturn(alias FuncSymbol)()
{
    return __traits(isSame, ReturnType!(FuncSymbol), int) ||
           __traits(isSame, ReturnType!(FuncSymbol), bool) ||
           __traits(isSame, ReturnType!(FuncSymbol), Object) ||
           __traits(isSame, ReturnType!(FuncSymbol), float) ||
           __traits(isSame, ReturnType!(FuncSymbol), void);
}

import std.traits : arity;
private bool isSupportedFunction(alias FuncSymbol)()
{
    // Arity must be 0
    return arity!(FuncSymbol) == 0 && isSupportedReturn!(FuncSymbol);
}

import guillotine.value;


import guillotine.value;
import guillotine.future;
import guillotine.provider;

// TODO: Make this a class and call it FutureTask which extends Task interface
public class FutureTask : Task
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
            import guillotine.result;
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

