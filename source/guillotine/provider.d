/** 
 * Defines the interface required for task submission
 * and the task itself
 */
module guillotine.provider;

/** 
 * Task submission interface
 */
public interface Provider
{
    /** 
     * This method must consume the provided task
     * for execution in the near future
     *
     * Params:
     *   task = the `Task` to consume
     */
    public void consumeTask(Task task);

    /** 
     * Starts this provider
     */
    public void start();

    /** 
     * Stops this provider
     *
     * The general contract here is that
     * this should prevent any fuirther
     * tasks from being submitted and if
     * some are still running then this
     * should hang till all have finished.
     *
     * Throws:
     *   `GuillotineException` on failure to stop
     */
    public void stop();
}

/** 
 * A task
 */
public interface Task
{
    /**
     * The function to run
     */
    public void run();
}