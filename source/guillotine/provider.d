module guillotine.provider;

import guillotine.task;

public interface Provider
{
    public void consumeTask(Task task);
}