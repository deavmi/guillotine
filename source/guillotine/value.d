module guillotine.value;

public struct Empty {}

public union ValueUnion
{
    Object object;
    int integer;
    uint uinteger;
    float floating;
    bool boolean;
    string str;
    Empty none;
}

public struct Value
{
    public ValueUnion value;

    this(Object value)
    {
        this.value.object = value;
    }

    // TODO: COme back to this and types
    this(int integer)
    {
        
    }
    
    // TODO: COme back to this and types
    this(uint uinteger)
    {
        this.value.uinteger = uinteger;
    }
}