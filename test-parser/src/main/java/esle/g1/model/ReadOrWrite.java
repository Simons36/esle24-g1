package esle.g1.model;

public class ReadOrWrite {
    public Latency latency;
    public Throughput throughput;

    // Getters and setters if necessary

    public static ReadOrWrite getNewReadOrWrite() {
        ReadOrWrite readOrWrite = new ReadOrWrite();
        readOrWrite.latency = new Latency();
        readOrWrite.throughput = new Throughput();
        return readOrWrite;
    }
}
