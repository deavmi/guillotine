/** 
 * Defines a result which is retruned
 * from the process of awaiting a future
 */
module guillotine.result;

import guillotine.value : Value;

/** 
 * Defines a `Result` which
 * is returned via a call
 * to a `Future`'s `await()'
 */
public struct Result
{
    /** 
     * The value of the result
     */
    private Value value;

    /** 
     * Constructs a new `Result` with
     * the given value
     *
     * Params:
     *   value = the `Value` of this result
     */
    this(Value value)
    {
        this.value = value;
    }

    /** 
     * Returns the value of this result
     *
     * Returns: the `Value`
     */
    public Value getValue()
    {
        return value;
    }

    /** 
     * Sets this result's value
     *
     * Params:
     *   value = the `value` to set to
     */
    public void setValue(Value value)
    {
        this.value = value;
    }
}