/** 
 * Serial execution strategy
 */
module guillotine.providers.sequential;

import libsnooze;
import guillotine.provider;
import std.container.slist;
import std.range : walkLength;
import core.sync.mutex : Mutex;
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
    private Event event;
    private SList!(Task) taskQueue;
    private Mutex taskQueueLock;
    private Thread runner;
    private bool running;

    /** 
     * Constricts a new `Sequential` provider
     */
    this()
    {
        this.event = new Event();
        this.taskQueueLock = new Mutex();
        this.runner = new Thread(&worker);
        this.event.ensure(runner);
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

        // Wake up the runner (just using all to avoid a catch for exception
        // ... which would occur if wait() hasn't been called atleast once
        // ... in `runner`
        event.notifyAll();

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
                // Sleep till awoken for an enqueue
                event.wait();

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
            catch(InterruptedException e)
            {
                // Handle by doing nothing, retry wait()
                continue;
            }
            catch(SnoozeError e)
            {
                // TODO: Stop and handle this
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

        try
        {
            // Notify the sleeping worker to wake up
            this.event.notify(runner);
        }
        catch(SnoozeError e)
        {
            throw new GuillotineException("Error notifying() sleeping worker in stop()");
        }

        // Wait for the runner thread to fully exit
        this.runner.join();

        // TODO: Destroy the libsnooze event here
    }
}