module guillotine.task;

import guillotine.value;
import guillotine.future;
import guillotine.provider;

// TODO: Make this a class and call it FutureTask which extends Task interface
public class FutureTask : Task
{
    // Related future for this task
    private Future future;

    // Function to call
    private Value function() func;

   
    public void run()
    {
        Value retVal = func();

        // TODO: wake future slpeers
        // TODO: Store retVal into it
    }
}