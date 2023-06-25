module guillotine.future;

// TODO: Examine the below import which seemingly fixes stuff for libsnooze
import libsnooze.clib;
import libsnooze;

import guillotine.result : Result;

public enum State
{
    NOT_STARTED,
    RUNNING,
    FINISHED,
    ERRORED
}

public final class Future
{
    /** 
     * `libsnooze` event
     */
    private Event event;

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
        this.event = new Event();
    }

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
            bool doneYet = false;
            while(!doneYet)
            {
                try
                {
                    event.wait();
                    doneYet = true;
                }
                catch(InterruptedException e)
                {
                    // Do nothing
                }
                catch(FatalException e)
                {
                    // TODO: Throw a FatalGuillaotine here
                    // TODO: make a custom guillotine exception
                }
            }

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
        this.event.notifyAll();
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
        this.event.notifyAll();
    }
}