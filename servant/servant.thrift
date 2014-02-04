namespace go  fun.rpc
namespace php fun.rpc

exception TMemcacheMissed {
    11: optional string message
}

struct req_ctx {
    /**
     * e,g. POST+/facebook/getPaymentRequestId/+34ca2cf6
     */
    1:required string caller

    /**
     * Where the request originated.
     */
    11:optional string host

    /**
     * Remote user IP address.
     */
    12:optional string ip

    /**
     * Session id.
     */
    13:optional string sid
}

/**
 * Thrift don't support service multiplex, so we have to bury all
 * services into the giant FunServant.
 *
 * We don't want to use different port for different service for 
 * multiplex of service, that will lead to complexity for client.
 */
service FunServant {
    /**
     * Ping.
     *
     * @return string - always 'pong'
     */
    string ping(
        1: required req_ctx ctx
    ),

    /**
     * Write a dlog event.
     *
     * timestamp will be generated by servant.
     *
     * @param req_ctx ctx - Request context
     * @param string ident - Log filename
     * @param string tag -
     * @param string json - Client is responsible to jsonize
     */
    oneway void dlog(
        /** request context */
        1: required req_ctx ctx, 
        2: required string ident, 
        3: required string tag, 
        4: required string json
    ),

    //=================
    // lcache section
    //=================

    bool lc_set(
        1: required req_ctx ctx, 
        2: required string key, 
        3: required binary value
    ),

    binary lc_get(
        1: required req_ctx ctx, 
        2: required string key
    ),

    oneway void lc_del(
        1: required req_ctx ctx, 
        2: required string key
    ),

    //=================
    // memcache section
    //=================

    /**
     * Set.
     *
     * @param req_ctx ctx - Request context info.
     * @param string key -
     * @param binary value -
     * @param i32 expiration - in seconds: either a relative time from now (up to 1 month), or 
     *     an absolute Unix epoch time. Zero means the Item has no expiration time.
     */
    bool mc_set(
        1: required req_ctx ctx, 
        2: required string key, 
        3: required binary value, 
        4: required i32 expiration
    ),

    /**
     * Get.
     *
     * @param req_ctx ctx - Request context info.
     * @param string key -
     * @return binary - Value of the key
     */
    binary mc_get(
        1: required req_ctx ctx, 
        2: required string key
    ) throws (
        1: TMemcacheMissed miss
    ),

    /**
     * Add.
     *
     * @param req_ctx ctx - Request context info.
     * @param string key -
     * @param binary value - Value of the key
     * @param i32 expiration -
     * @return bool - False if the key already exists.
     */
    bool mc_add(
        1: required req_ctx ctx, 
        2: required string key, 
        3: required binary value, 
        4: required i32 expiration
    ),

    /**
     * Delete.
     *
     * @param req_ctx ctx - Request context info.
     * @param string key -
     * @return bool - True if Success 
     */
    bool mc_delete(
        1: required req_ctx ctx, 
        2: required string key
    ),

    /**
     * Increment.
     *
     * @param req_ctx ctx - Request context info.
     * @param string key -
     * @param i32 delta - If negative, means decrement
     * @return binary - New value of the key
     */
    i32 mc_increment(
        1: required req_ctx ctx, 
        2: required string key, 
        3: required i32 delta
    ),

    //=================
    // mongodb section
    //=================

}
