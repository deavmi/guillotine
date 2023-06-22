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

   
    public void run()
    {
        Value retVal = func();

        // TODO: wake future slpeers
        // TODO: Store retVal into it
    }
}

