package com.pda_rfid_scanner.utils;

public interface IDataReceive {
    /**
     * 获取刷卡数据
     * 
     * @param data 刷卡数据0x36开头0x19结尾
     */
    public void onLFDataReceived(byte[] data);
}
