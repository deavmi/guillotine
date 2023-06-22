module guillotine.task;

import guillotine.value;
import guillotine.future;

public struct Task
{
    // Related future for this task
    private Future future;

    // Function to call
    private Value function() func;

   
    public Value run()
    {
        Value retVal = func();

        // TODO: wake future slpeers

        return retVal;
    }
}