module guillotine.provider;

public interface Provider
{
    public void consumeTask(Task task);
}

public interface Task
{
    public void run();
}