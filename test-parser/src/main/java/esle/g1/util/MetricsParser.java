package esle.g1.util;

import com.fasterxml.jackson.databind.ObjectMapper;

import esle.g1.model.Metrics;
import esle.g1.model.ReadOrWrite;
import java.io.File;
import java.io.IOException;

public class MetricsParser {
    private ObjectMapper mapper;

    public MetricsParser() {
        this.mapper = new ObjectMapper();
    }

    public ReadOrWrite parseReadFromFile(String filePath) throws IOException {
        Metrics metrics = mapper.readValue(new File(filePath), Metrics.class);
        return metrics.Read;  // Only return "Read"
    }

    public ReadOrWrite parseWriteFromFile(String filePath) throws IOException {
            
        Metrics metrics = mapper.readValue(new File(filePath), Metrics.class);
        return metrics.Write;  // Only return "Write"
    }
}
