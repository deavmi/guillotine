/** 
 * Defines a value that is part
 * of a result
 */
module guillotine.value;

/** 
 * Represents a void value
 */
public struct Empty {}

/** 
 * Union defining the allocated space
 * for the value
 */
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

/** 
 * The value wrapper around the `ValueUnion`
 * union
 */
public struct Value
{
    /** 
     * The actual value in union
     * format
     */
    public ValueUnion value;

    // TODO: COme back to this
    private this(Object value)
    {
        this.value.object = value;
    }

    // TODO: COme back to this and types
    private this(int integer)
    {
        
    }
    
    // TODO: COme back to this and types
    private this(uint uinteger)
    {
        this.value.uinteger = uinteger;
    }
}