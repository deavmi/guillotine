/** 
 * Defines the `Future` type and related types
 */
module guillotine.future;

import core.sync.mutex : Mutex;
import core.sync.condition : Condition;
import core.sync.exception : SyncError;

import guillotine.result : Result;

/** 
 * Defines the state of the `Future`
 */
public enum State
{
    NOT_STARTED,
    RUNNING,
    FINISHED,
    ERRORED
}

/** 
 * Defines a future
 */
public final class Future
{
    /** 
     * Mutex for condition
     * variable
     */
    private Mutex mutex;

    /** 
     * Condition variable
     * used for signalling
     */
    private Condition signal;

    /** 
     * State of the future
     */
    package State state = State.NOT_STARTED;

    /** 
     * The result of the task (on success)
     */
    private Result result; // TODO: Volatile maybe?

    /** 
     * The error result (on error)
     */
    private Exception errResult; // TODO: Volatile maybe?

    /** 
     * Constructs a new `Future`
     */
    public this()
    {
        this.mutex = new Mutex();
        this.signal = new Condition(this.mutex);
    }

    /** 
     * Awaits this future either returning the result
     * from its computation throwing the exception which
     * occurred during it.
     *
     * Returns: the `Result` from the computation
     * Throws:
     *   `GuillotineException` on fatal error
     * Throws:
     *   `Exception` the exception that occurred during
     * computation
     */
    public Result await()
    {
        // If we are already finished, return the value
        if(this.state == State.FINISHED)
        {
            return this.result;
        }
        // If we had an error then throw the error
        else if(this.state == State.ERRORED)
        {
            throw errResult;
        }
        // If we are in RUNNING or NOT_STARTED
        // (Note: this can happen in executor usage too
        // ( instead of just standalone usage as the time before
        // the FutureTask sets to RUNNING and when our main thread
        // calls await() can have it pickup on the NOT_STARTED case)
        else
        {            
            // Lock mutex
            this.mutex.lock();

            // Wait on condition variable
            this.signal.wait();

            // TODO: Add syncerror checking?
            
            // Unlock mutex
            this.mutex.unlock();


            // If we had an error then throw it
            if(this.state == State.ERRORED)
            {
                throw this.errResult;
            }
            // If we finished successfully, then return the result
            // (Note: That is the only way this branch would run)
            else
            {
                return this.result;
            }
        }
    }

    /** 
     * Sets this `Future` as completed by storing the
     * provided result into it and waking up anybody
     * who was awaiting it
     *
     * Params:
     *   result = the task's result
     *
     * Throws:
     *   TODO: Handle the libsnooze event
     */
    package void complete(Result result)
    {
        // Store the result
        this.result = result;

        // Set the state
        this.state = State.FINISHED;

        // Wake up any sleepers
        this.signal.notifyAll();
    }

    /** 
     * Sets this `Future` into the error state and wakes
     * up anybody who was awaiting it
     *
     * Params:
     *   errResult = the `Exception` which occurred
     * Throws:
     *   TODO: handle the libsnooze event
     */
    package void error(Exception errResult)
    {
        // Store the error
        this.errResult = errResult;

        // Set the state
        this.state = State.ERRORED;

        // Wake up any sleepers
        this.signal.notifyAll();
    }
}