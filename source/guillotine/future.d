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
    package Event event;

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
}