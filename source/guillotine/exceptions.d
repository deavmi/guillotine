/** 
 * Exception types
 */
module guillotine.exceptions;

/** 
 * The guillotine exception type
 */
public class GuillotineException : Exception
{
    /** 
     * Constructs a new `GuillotineException` with
     * the given error message
     *
     * Params:
     *   msg = the error message
     */
    this(string msg)
    {
        super(msg);   
    }
}