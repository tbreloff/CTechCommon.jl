
abstract ScheduledEvent

@pretty immutable StopEvent <: ScheduledEvent
	time::TimeOfDay
end

# this encompasses everything we need to know about when/how to do the scheduled event
@pretty immutable NormalEvent <: ScheduledEvent
	time::TimeOfDay   				# when this should run
	pub::Publisher            # the publisher to be scheduled (which contains both the function call and receivers/listeners)
	args 											# the arguments to the function
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
	stopTime::TimeOfDay
	eventList::SinglyLinkedList{ScheduledEvent}
	LiveScheduler() = (s = new(); empty!(s); s)
end

NOW(scheduler::LiveScheduler) = currentTimeOfDay()

function Base.empty!(scheduler::LiveScheduler)
	scheduler.stopTime = typemax(TimeOfDay)
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
	currentTime::TimeOfDay
	stopEvent::TimeOfDay
	eventList::SinglyLinkedList{ScheduledEvent}
	SimulationScheduler() = (s = new(); empty!(s); s)
end

NOW(scheduler::SimulationScheduler) = scheduler.currentTime

function Base.empty!(scheduler::SimulationScheduler)
	scheduler.currentTime = 0
	scheduler.stopTime = typemax(TimeOfDay)
	scheduler.eventList = SinglyLinkedList(ScheduledEvent)
end

function publish(scheduler::SimulationScheduler, event::ScheduledEvent)
	scheduler.currentTime = event.time
	publish(event.pub, event.args...)
	return
end

function publish(scheduler::SimulationScheduler, time::TimeOfDay, pub::Publisher, args...)
	scheduler.currentTime = time
	publish(pub, args)
	return
end

# --------------------------------------------------------------

# this is a global constant (also a singleton), so that schedule can easily be called from anywhere without passing
# around the SCHEDULER object
const SCHEDULER = SimulationScheduler()  # TODO: allow choice between sim/live somehow

NOW() = NOW(SCHEDULER)
initScheduler() = empty!(SCHEDULER)
stopScheduler(time::TimeOfDay) = (insertSorted!(SCHEDULER.eventList, StopEvent(time), compareEventTimes); return)

# stop the loop by adding a "stop event" to the queue
# const stopEvent = ScheduledEvent()
# stopScheduler(time::TimeOfDay) = (stopEvent.time = time; schedule(stopEvent); nothing)

# --------------------------------------------------------------

# returns true when we should stop
processEvent(event::NormalEvent) = (publish(SCHEDULER, event); false)
processEvent(event::StopEvent) = true


# these functions should be called from non-main-loop areas... schedule the event, and don't worry about how it gets run
function Base.schedule(time::TimeOfDay, pub::Publisher, args...)
	event = ScheduledEvent(time, pub, args)
	insertSorted!(SCHEDULER.eventList, event, compareEventTimes)
	event
end


# call this one from the "main loop"... it either runs the function immediately or schedules and clears the queue
# note: returns true if we should stop the main loop
function schedule_do(time::TimeOfDay, pub::Publisher, args...)
	if isQueueEmpty(SCHEDULER) || time < firstTimeInQueue(SCHEDULER)
		
		# do this immediately
		publish(SCHEDULER, time, pub, args...)
		return false

	else
		# add to the queue
		event = schedule(time, pub, args...)

		# clear out the queue until we get to the new event
		while !isQueueEmpty(SCHEDULER)
			nextevent = shift!(SCHEDULER.eventList)  # gets the first in the list
			processEvent(nextevent) && return true # stopped... return true
			nextevent === event && return false # processed this one... return false
		end
	end	

	# shouldn't actually get here...
	return false
end



