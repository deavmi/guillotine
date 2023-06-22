module guillotine.result;

import guillotine.value : Value;

public struct Result
{
    private Value value;

    public Value getValue()
    {
        return value;
    }

    public void setValue(Value value)
    {
        this.value = value;
    }
}