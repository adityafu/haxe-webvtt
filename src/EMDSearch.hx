enum EMDSearch {

    /**
     * Search for the first occurrence of the given string.
     */
    Search(value:String,total:Float,workerID:Float,?result:Array<Array<CuesResult>>);

    /**
     * Search for the last occurrence of the given string.
     */
    Unknow;

    Initialized(dbName:Array<String>,?workerID:Float);
    
}