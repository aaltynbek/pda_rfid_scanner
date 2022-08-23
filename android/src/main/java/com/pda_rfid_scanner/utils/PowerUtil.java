package com.pda_rfid_scanner.utils;

import java.io.FileWriter;

public class PowerUtil {

    private static String TAG = "PowerUtil";
    private final static String UHF = "/proc/gpiocontrol/set_uhf";

    public static boolean power(String id) {
        try {
            FileWriter localFileWriterOn = new FileWriter(UHF);
            localFileWriterOn.write(id);
            localFileWriterOn.close();
            // Thread.sleep(200);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

}
