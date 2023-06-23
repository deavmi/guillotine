module guillotine.provider;

public interface Provider
{
    public void consumeTask(Task task);
    public void start();
    public void stop();
}

public interface Task
{
    public void run();
}