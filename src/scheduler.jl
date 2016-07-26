
abstract ScheduledEvent

immutable StopEvent <: ScheduledEvent
	time::TimeOfDay
end

# this encompasses everything we need to know about when/how to do the scheduled event
immutable NormalEvent{T} <: ScheduledEvent
	time::TimeOfDay   				# when this should run
	pub::Publisher            # the publisher to be scheduled (which contains both the function call and receivers/listeners)
	args::T 											# the arguments to the function
end

# Base.string(event::ScheduledEvent) = (isdefined(event,:pub) ? "Event{time=$(event.time), $(event.pub), $(event.args)}" : "Event{time=$(event.time)}")
# @createIoMethods ScheduledEvent
# Base.print(io::IO, event::ScheduledEvent) = print(io, string(event))
# Base.show(io::IO, event::ScheduledEvent) = print(io, string(event))

compareEventTimes(a1::ScheduledEvent, a2::ScheduledEvent) = return (a1.time < a2.time ? -1 : (a1.time == a2.time ? 0 : 1))

# --------------------------------------------------------------

# this type represents something that can handle scheduling publishing sometime in the future
# it will be the "main loop".  In simulation, it will keep track of "simulation time" and 
# properly order events while updating the time.
# In production/live scheduling, it will use clock time and sleep/wake at appropriate times, while
# ideally polling various sockets for market data, orders, etc
abstract Scheduler

# some helper functions
isQueueEmpty(scheduler::Scheduler) = isempty(scheduler.eventList)
firstTimeInQueue(scheduler::Scheduler) = peek(scheduler.eventList).time


# --------------------------------------------------------------

type LiveScheduler
	timeOfLastEvent::TimeOfDay
	eventList::SinglyLinkedList{ScheduledEvent}
	LiveScheduler() = (s = new(); empty!(s); s)
end

NOW(scheduler::LiveScheduler) = currentTimeOfDay()

function Base.empty!(scheduler::LiveScheduler)
	scheduler.timeOfLastEvent = 0
	scheduler.eventList = SinglyLinkedList(ScheduledEvent)
end

# TODO:
function publish(scheduler::LiveScheduler, event::ScheduledEvent)
	return
end
function publish(scheduler::LiveScheduler, time::TimeOfDay, pub::Publisher, args...)
	return
end

# --------------------------------------------------------------

type SimulationScheduler <: Scheduler
	timeOfLastEvent::TimeOfDay
	eventList::SinglyLinkedList{ScheduledEvent}
	SimulationScheduler() = (s = new(); empty!(s); s)
end

NOW(scheduler::SimulationScheduler) = scheduler.timeOfLastEvent

function Base.empty!(scheduler::SimulationScheduler)
	scheduler.timeOfLastEvent = 0
	scheduler.eventList = SinglyLinkedList(ScheduledEvent)
end

function publish(scheduler::SimulationScheduler, event::ScheduledEvent)
	scheduler.timeOfLastEvent = event.time
	publish(event.pub, event.args...)
	return
end

function publish(scheduler::SimulationScheduler, time::TimeOfDay, pub::Publisher, args...)
	scheduler.timeOfLastEvent = time
	publish(pub, args...)
	return
end

# --------------------------------------------------------------

# this is a global constant (also a singleton), so that schedule can easily be called from anywhere without passing
# around the SCHEDULER object
const SCHEDULER = SimulationScheduler()  # TODO: allow choice between sim/live somehow

NOW() = NOW(SCHEDULER)
initScheduler() = empty!(SCHEDULER)
stopScheduler(time::TimeOfDay = zero(TimeOfDay)) = (insertSorted!(SCHEDULER.eventList, StopEvent(time), compareEventTimes); return)


# --------------------------------------------------------------

# returns true when we should stop
processEvent(event::NormalEvent) = (publish(SCHEDULER, event); false)
processEvent(event::StopEvent) = (SCHEDULER.timeOfLastEvent = event.time; true)


# these functions should be called from non-main-loop areas... schedule the event, and don't worry about how it gets run
function Base.schedule(time::TimeOfDay, pub::Publisher, args...)
	event = NormalEvent(time, pub, args)
	insertSorted!(SCHEDULER.eventList, event, compareEventTimes)
	event
end

Base.schedule(time::TimeOfDay, cb::Callback, args...) = schedule(time, cb.pub, args...)

# call this method from the "main loop"... it either:
#		1) runs the function immediately, or
#		2) schedules the event and clears the queue up to and including that event
# note: returns true if we hit a StopEvent
# note: this function is really intended for the situation that a stream of events is "driving time forward", 
#				such as historical market data.  if there are no other events waiting, just keep processing the 
#				main event stream as quickly as possible
function schedule_do(time::TimeOfDay, pub::Publisher, args...)

	# clear out the queue until the current time
	while !isQueueEmpty(SCHEDULER) && time >= firstTimeInQueue(SCHEDULER)
		nextevent = shift!(SCHEDULER.eventList)  # gets the first in the list
		processEvent(nextevent) && return true # stopped... return true
	end

	# now publish it
	publish(SCHEDULER, time, pub, args...)
	false
end


# --------------------------------------------------------------

# handle scheduling the same thing multiple times

function Base.schedule(times::AbstractVector{TimeOfDay}, args...)
	for t in times
		schedule(t, args...)
	end
end

function schedule_do(times::AbstractVector{TimeOfDay}, args...)
	for t in times
		schedule_do(t, args...)
	end
end

# --------------------------------------------------------------

# process events in order until either the queue is empty (returns false) or
# we hit a StopEvent (returns true)
function processAllEvents()
	while !isQueueEmpty(SCHEDULER)
		nextevent = shift!(SCHEDULER.eventList)  # gets the first in the list
		processEvent(nextevent) && return true # stopped... return true
	end
	return false
end


