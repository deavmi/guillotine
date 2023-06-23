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

    this()
    {
        this.event = new Event();
        this.taskQueueLock = new Mutex();
        this.runner = new Thread(&worker);
    }

    public override void consumeTask(Task task)
    {
        version(unittest)
        {
            writeln("Sequential: Consuming task '", task, "'...");
        }

        // Lock the queue
        taskQueueLock.lock();

        // TODO: Implement me

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
        runner.start();
    }   

    public void worker()
    {
        // TODO: Add running condition here?
        while(true)
        {
            try
            {
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

                // Sleep till awoken for an enqueue
                event.wait();
                
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

    public void stop()
    {
        // TODO: set flag

        // TODO: notify
    }
}