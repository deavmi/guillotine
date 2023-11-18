/** 
 * Serial execution strategy
 */
module guillotine.providers.sequential;

import guillotine.provider;
import std.container.slist;
import std.range : walkLength;
import core.sync.mutex : Mutex;
import core.sync.condition : Condition;
import core.sync.exception : SyncError;
import core.time : Duration, dur;

import core.thread : Thread;
import guillotine.exceptions;

version(unittest)
{
    import std.stdio : writeln;
}

/** 
 * Provides sequential or "serial" execution
 * on a singular thread of the consumed tasks
 */
public final class Sequential : Provider
{
    private Mutex mutex;
    private Condition event;
    private SList!(Task) taskQueue;
    private Mutex taskQueueLock;
    private Thread runner;
    private bool running;
    private Duration wakeInterval;

    /** 
     * Constricts a new `Sequential` provider
     */
    this()
    {
        this.mutex = new Mutex();
        this.event = new Condition(this.mutex);
        this.taskQueueLock = new Mutex();
        this.runner = new Thread(&worker);

        // TODO: Choose a sane efault
        this.wakeInterval = dur!("msecs")(10);
    }

    /** 
     * Sets the interval at which the runner
     * must forcefully wakeup from slumber
     * and check for any new jobs - in
     * the case one was submitted prior
     * to sleeping.
     *
     * Note that must of the time slumber
     * will stopped if a task is submitted
     * WHILST we are ALREADY sleeping. This
     * is to aid in the times where that is
     * NOT the case
     *
     * Params:
     *   interval = the `Duration`
     */
    public void setWakeInterval(Duration interval)
    {
        this.wakeInterval = interval;
    }

    /** 
     * Returns the slumber interval
     *
     * Returns: the `Duration`
     */
    public Duration getWakeInterval()
    {
        return this.wakeInterval;
    }

    /** 
     * Consumes the provided task for
     * execution in the near future
     *
     * Params:
     *   task = the `Task` to consume
     */
    public override void consumeTask(Task task)
    {
        version(unittest)
        {
            writeln("Sequential: Consuming task '", task, "'...");
        }

        // Lock the queue
        taskQueueLock.lock();

        // Append the task
        taskQueue.insertAfter(taskQueue[], task);

        // Unlock the queue
        taskQueueLock.unlock();

        // Wake up the runner
        event.notify();

        version(unittest)
        {
            writeln("Sequential: Task '", task, "' consumed");
        }
    }

    /** 
     * Starts the provider's execution thread
     */
    public void start()
    {
        // Set the running flag to true
        this.running = true;

        // Start the runner thread
        runner.start();
    }   

    public void worker()
    {
        // TODO: Add running condition here?
        while(running)
        {
            try
            {
                // Lock mutex
                this.mutex.lock();

                // Sleep till awoken for an enqueue
                import std.stdio;
                writeln("Worker wait...");
                bool b = event.wait(this.wakeInterval);
                writeln("Worker wait... [done] ", b);

                // TODO: Add syncerror checking?

                // Unlock mutex
                this.mutex.unlock();


                // Check if we are running, if not, exit
                if(!running)
                {
                    continue;
                }

                // Lock the queue
                taskQueueLock.lock();

                // Potential item to process
                Task potTask;

                // If there are any items
                if(walkLength(taskQueue[]) > 0)
                {
                    // Get the front item
                    potTask = taskQueue.front();

                    // Remove the item
                    taskQueue.linearRemoveElement(potTask);
                }

                // Unlock the queue
                taskQueueLock.unlock();

                // If there was an item, then run it now
                if(potTask !is null)
                {
                    potTask.run();
                }

            }
            catch(SyncError e)
            {
                // TODO: What to do?
                // Handle by doing nothing, retry wait()
                import std.stdio;
                writeln("SyncError: ", e);
                continue;
            }
        }
    }

    /** 
     * Stops the provider.
     *
     * If there is a task executing currently
     * then it will finish, any other submitted
     * tasks will not be run.
     *
     * This method will hang till said task
     * has finished executing.
     *
     * Throws:
     *   `GuillotineException` on error stopping
     * the worker
     */
    public void stop()
    {
        // Set running flag to false
        this.running = false;

        // Notify the sleeping worker to wake up
        this.event.notify();

        // Wait for the runner thread to fully exit
        this.runner.join();
    }
}