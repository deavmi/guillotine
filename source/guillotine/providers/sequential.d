module guillotine.providers.sequential;

import libsnooze;
import guillotine.provider;
import std.container.slist;
import core.sync.mutex : Mutex;
import core.thread : Thread;

version(unittest)
{
    import std.stdio : writeln;
}

public final class Sequential : Provider
{
    private Event event;
    private SList!(Task) taskQueue;
    private Mutex taskQueueLock;
    private Thread runner;
    private bool running;

    this()
    {
        this.event = new Event();
        this.taskQueueLock = new Mutex();
        this.runner = new Thread(&worker);
        this.event.ensure(runner);
    }

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

    public void start()
    {
        // TODO: Set flag
        this.running = true;

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
                import std.range;
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

                // TODO: After wait check if boolean
                // ... was flipped to stop (no longer run)
            }
            catch(InterruptedException e)
            {
                // TODO: Handle by doing nothing
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
     */
    public void stop()
    {
        // TODO: set flag
        this.running = false;

        // TODO: notify
        this.event.notify(runner);

        // TODO: Should we hang here till finished?
        this.runner.join();
    }
}