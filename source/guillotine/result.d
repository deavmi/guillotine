module guillotine.result;

import guillotine.value : Value;

/** 
 * Defines a `Result` which
 * is returned via a call
 * to a `Future`'s `await()'
 */
public struct Result
{
    private Value value;

    this(Value value)
    {
        this.value = value;
    }

    public Value getValue()
    {
        return value;
    }

    public void setValue(Value value)
    {
        this.value = value;
    }
}