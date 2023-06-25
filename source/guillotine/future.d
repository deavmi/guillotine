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
    private State state = State.NOT_STARTED;

    /** 
     * The result of the task
     */
    private Result result; // TODO: Volatile maybe?

    /** 
     * Constructs a new `Future` with the given
     * underlying `libsnooze` event to be used
     * for waking awaiting threads
     *
     * Params:
     *   event = the `Event` object
     */
    package this(Event event)
    {
        this.event = event;
    }

    // TODO: Clean up above and make us make the future's event
    // ... the user shouldn't have to pass one in
    package this()
    {
        this(new Event());
    }

    public Result await()
    {
        // TODO: kak
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
            }
        }

        if(this.state == State.ERRORED)
        {
            // TODO: Throw an exception then
            throw new Exception("Had error");
        }
        else if(this.state == State.FINISHED)
        {
            return this.result;
        }
        else
        {
            // TODO: handle this earlier on
            return Result();
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
     * Throws:
     *   TODO: handle the libsnooze event
     */
    package void error()
    {
        // Set the state
        this.state = State.ERRORED;

        // Wake up any sleepers
        this.event.notifyAll();
    }
}