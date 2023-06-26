/**
 * Executor framework with future-based task submission
 * and pluggable thread execution engines
 */
module guillotine;

/** 
 * Executor service for task submission and tracking
 */
public import guillotine.executor : Executor;

/** 
 * Defines the interface required for task submission
 * and the task itself
 */
public import guillotine.provider : Provider;

/** 
 * Defines the `Future` type and related types
 */
public import guillotine.future : Future;

// TODO: Clean this below one up later
/** 
 * Defines a result which is retruned
 * from the process of awaiting a future
 */
public import guillotine.result : Result;

/** 
 * Defines a value that is part
 * of a result
 */
public import guillotine.value : Value, ValueUnion, Empty;

/** 
 * Exception types
 */
public import guillotine.exceptions;