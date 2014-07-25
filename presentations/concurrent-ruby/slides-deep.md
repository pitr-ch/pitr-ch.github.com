class: center, inverse, middle

# Concurrent .red[Ruby]

???

-   I'll be talking about rubygem called concurrent-ruby today.
-   I'll give you a short introduction of RubyGem called concurrent-ruby.

# Keep in mind

-   explain each abstraction
-   intonation do not go up at the end of a sentence
-   talk clearly, do not mumble
-   s/this/that/
-   do not rush to switch slides
-   give people time to read the slide

---
# About me

```ruby
[ speaker.name             == 'Petr Chalupa',
  speaker.works_at         == :'Red Hat',
  speaker.is               == RubyEnthusiast,
  speaker.latest_obsession == %|Concurrency|
].all? or
    raise TypeError
```

???

-   But first let me introduce myself.

---
# What is .red[concurrent-ruby]?

-   RubyGem
-   Toolset
-   Collection of 
    -   **low-level** constructs
    -   **high-level** abstractions

.pull-right[![concurrent-ruby-logo](images/concurrent-ruby-logo.png)]

_Developer's <sup>be-</sup><sub>friend</sub><sup>st</sup> for <sub>ency.</sub><sup>concurr-</sup>_

???

-   Started by [@jdantonio](https://github.com/jdantonio), now over 15 contributors
-   it's not a single tool to solve one problem but toolset, ...
-   Do not tell jokes!

---
# Objectives of .red[concurrent-ruby]

.red[Ruby] does not have a good concurrent story.

--

-   Filling the gap
-   Trying to gather concurrent tools at one place
-   Unopinionated
-   Easy to share 
-   To help with building more concurrent libraries/gems
-   _Maybe to prove other languages that we can do it too._

???

-   MRI has GIL, ruby is not used much for concurrent programming.
    -   But with JRuby ir makes sense
-   .
-   .
-   One of the reasons for the generic name; 
    works the same on MRI, JRuby or Rubinius, there is always a pure Ruby fallback;
    for different problems there are different solutions
-   No deps!
-   Decoupled; primitives

---
class: middle, center, inverse
# And .red[why] am I talking about it?

???

-   My hope today is that you find this short introduction interesting, 
    and you'll remember and look up this gem again to solve your concurrent problem.

---
class: middle, center, inverse
# What is .red[concurrent-ruby]?

A collection of ...

---
## Low-level constructs

-   Atomics
    -   AtomicInteger
    -   AtomicBoolean
    -   Atomic _(v0.7.0.rc2)_
-   Synchronization primitives:
    -   CountDownLatch
    -   Event
    -   Condition
-   ThreadLocalVar
-   IVar
-   MVar ➤ Exchanger
-   Delay ➤ LazyRegister

???

-   0.7.rc1 is already out
-   atomic merged, thanks to Charles Nutter and the community
-   unfortunately I do not have time to talk about those more

---
## High-level abstracts

-   Executors
-   Async
-   TimerTask
-   Actor _(v0.7.0.rc2)_
-   TVar (STM)
-   Future
-   Promise
-   Channel
-   Agent

???

-   shortly describe the last for

---
class: middle, center, inverse
# Examples

### gem install .red[concurrent-ruby]
 
???

-   lets install and look at some code

---
# Executors

Inspired by Java. There are:

-   FixedThreadPool
-   CachedThreadPool
-   ImmediateExecutor
-   PerThreadExecutor
-   SingleThreadExecutor

```ruby
pool = Concurrent::FixedThreadPool.new(5)
pool.post { a_job }
```

???

-   same API, `#post`
-   two global pools `global_task_pool`, `global_operation_pools`

---
# Delay

```ruby
def db
  @db ||= connect_database
end

queue = Queue.new

2.times do
  Thread.new { queue << db } 
end

queue.pop.eq queue.pop # => ?
```

???

-   Q: Who thinks this is not safe?

---
# Delay

Reference to a lazy-evaluated memorized value.

```ruby
@db = Concurrent::Delay.new { connect_database }


def db
  @db.value # blocks until computed, returns the evaluated value
end

queue = Queue.new

2.times do
  Thread.new { queue << db } 
end

queue.pop.eq queue.pop # => true
```

???

-   executes on the `global_task_pool`
    -   can be configured to ImmediateExecutor or any other

---
# Async

Adds asynchronous behavior to any object.

```ruby
class Echo
  include Concurrent::Async
  
  def initialize
    init_mutex # initialize the internal synchronization objects
  end
  
  def echo(message)
    sleep(rand)
    puts message
  end
end

horn = Echo.new

horn.echo('zero')      # synchronous,                not thread-safe

horn.async.echo('one') # asynchronous, non-blocking, thread-safe
horn.await.echo('two') # synchronous,  blocking,     thread-safe
```

???

-   simple pattern to start with background tasks
-   serialized executions

---
class: middle, center, inverse
# Now the .red[good] stuff!

---
# Actor

Inspired by Erlang and Akka.

-   Runs on thread-pool
-   Linking
-   Supervising
-   Dead letter routing
-   Highly customizable with Behaviors
-   Coming in 0.7

???

-   which is the part I've contributed
-   like objects and sending messages, but everything is async

bullets in slide:
-   1000s of actors
-   to monitor
-   to reset, restart, or terminate on error
-   to track undelivered messages

---
## Actor - example

```ruby
class Adder < Concurrent::Actor::RestartingContext
  def initialize(init)
    @count = init
  end
  def on_message(message)
    case message
    when :add
      @count += 1
    else
      pass
    end
  end
end

adder = Adder.spawn(name: :adder, supervise: true, args: [1])
# => #<Concurrent::Actor::Reference /adder (Adder)>
adder.parent
# => #<Concurrent::Actor::Reference / (Concurrent::Actor::Root)>

adder.tell(:add) << :add   # => the reference
adder.ask!(:add)           # => 4
adder.ask!(:any) rescue $! # => exception: "UnknownMessage: :any"
adder.ask!(:add)           # => 2
adder.ask!(:terminate!)    # => true
```

???

-   actor library is probably the most complex part of concurrent-ruby, showing just simple example
-   explain the actor first
-   tree structure
-   any actor spawned outside other actor will get the root actor
-   sending messages, chaining
-   asking for result
-   fails and restarts
-   terminate the actor, let it be GCed   

---
# STM

Software transactional memory inspired by Clojure.

**The problem:**

```ruby
Account       = Struct.new(:balance)
alice_account = Account.new 100
adam_account  = Account.new 100

def transfer(amount, from, to)
  return from.balance -= amount,
      to.balance += amount
end

transfer 20, alice_account, adam_account # => [80, 120]
```

???

-   lets start with a problem description where STM helps first
-   -= and += are not atomic
-   now we'll try to fix it in few iterations
-   I'll ignore for sake of simplicity compensation code 
    when first or second operation on account fails       

---
## STM - Coarse locking

```ruby
alice_account = 100
adam_account  = 100
ACCOUNTS_LOCK = Mutex.new

def transfer(amount, from, to)
  ACCOUNTS_LOCK.lock
  return from -= amount,
         to   += amount
ensure
  ACCOUNTS_LOCK.unlock
end

transfer 20, alice_account, adam_account # => [80, 120]
```

???

-   thread safe
-   only single transfer at a time
-   more threads do not scale

---
## STM - Fine locking

```ruby
Account       = Struct.new(:lock, :balance)
alice_account = Account.new Mutex.new, 100
adam_account  = Account.new Mutex.new, 100

def transfer(amount, from, to)
  from.lock.lock
  to.lock.lock
  return from.balance -= amount,
      to.balance += amount
ensure
  from.lock.unlock
  to.lock.unlock
end

transfer 20, alice_account, adam_account # => [80, 120]

```

???
-   Q: is it safe?
--

```ruby
Thread.new { transfer 20, alice_account, adam_account }
Thread.new { transfer 10, adam_account, alice_account }
```

???
-   A: No

---
## STM - Fixed fine locking

```ruby
ACCOUNT_COUNTER = Concurrent::AtomicFixnum.new
Account         = Class.new(Struct.new(:id, :lock, :balance))

def Account.new(balance)
  super ACCOUNT_COUNTER.increment, Mutex.new, balance
end

alice_account = Account.new 100
adam_account  = Account.new 100

def transfer(amount, from, to)
  order = [from, to].sort_by(&:id)
  order.each { |account| account.lock.lock }
  return from.balance -= amount,
      to.balance += amount
ensure
  order.reverse_each { |account| account.lock.unlock }
end

transfer 20, alice_account, adam_account # => [80, 120]

```

???

-   add a total order between the locks to avoid deadlocking
-   for this to work in your app the order has to be on all locks in the app
-   still does not solve compensation

---
## STM - Example

```ruby
my_account   = Concurrent::TVar.new(100)
your_account = Concurrent::TVar.new(100)

def transfer(from, to, amount)
  Concurrent.atomically do
    return from.value -= amount,
        to.value += amount
  end
end

transfer my_account, your_account, 20 # => [80, 120]

```
???
-   safe out of the box
-   simple to use
-   may re-run the block
    -   has to be side-effect free (no modification)   
--

### Performance

-   Scales the best
-   But the safety comes with overhead.

???
-   gains most by adding threads
-   absolutely faster at around 50 cores
-   provides ACID (Atomicity, Consistency, Isolation) without Durability

---
class: middle, center, inverse
name: jruby
# concurrent-ruby on .red[JRuby]

.middle[![jruby-bird](images/jruby-bird.png)]

---
# Native Java implementations

-   AtomicBoolean
-   AtomicFixnum
-   Atomic
-   CountDownLatch
-   ThreadLocalVar
-   Executors

Speedup:

-   Average: **3.7**

???

-   Median: slightly less 2.8 because 
-   top speed up 18

---
# MRI vs JRuby

```txt
messages  actors     total       real
   50000       2  7.000000  (3.261000)
   50000    1000  8.950000  (2.659000)
   50000    3000  9.790000  (3.194000)
```

```txt
messages  actors     total       real
   50000       2  4.360000  (4.084465)
   50000    1000  6.730000  (5.873954)
   50000    3000  7.520000  (6.613830)

```

> _msgs = messages, acts = actors, total = process time, real = real time_

???

-   Benchmark of Actors, 50_000 messages
-   Q: can you ques which one belongs to JRuby? Rise hands for the second.

--

.red[JRuby] is first.

???
-   the real time is much faster than process time
-   JRuby has no GIL, can run multiple threads.
-   I think this nicely demonstrates why is better to use JRuby for concurrency.
-   BTW this also shows that almost no overhead on actor count

---
class: middle, center, inverse
# Who uses .red[concurrent-ruby]?

???

-  Real world usage 

---
# Dynflow

-   .red[Dyn]amic Work.red[flow] Engine
-   Parallel execution of tasks and its actions
-   Allows to pause tasks on error, fix the issue, and resume the execution
-   Action suspending to free Threads

.right[![dynflow](images/dynflow.png)]

???

-   Co-authored
-   Actions also parallelized if dependency allows.
-   unfortunately migration to concurrent-ruby is still in progress so it runs 
    on simpler actor implementation I wrote just for Dynflow before

---
# Foreman + Katello = Satellite 6

Complete lifecycle management tool for physical and virtual servers.

-   Foreman
    -   Provisioning
    -   Initial configuration
    -   Drift management       
    -   Supports: Bare metal, libvirt, oVirt, VMware, EC2, OpenStack, more.

.pull-right[
![foreman](images/foreman.png)
![katello](images/katello.png)
]

-   Katello
    -   Content management
        -   RPMS
        -   Puppet modules
    -   Orchestration of subsystems with Dynflow (Pulp, Candlepin, Elasticsearch)
    
???

Dynflow to orchestrate pulp and candlepin

---
# Staypuft

Easy to use OpenStack Installer. Fully automated installation of OpenStack with HA support using Dynflow. 

# AeroExpress

Station server for "AeroExpress" trains from/to Moscow airports. It manages dozens of NFC-readers and turnstile controllers.

# EventSourcing

EventSourcing framework for a trading application and a BaaS/CMS.

???

-   Q: Do you know OpenStack?
-   Massive system, needs orchestration to install.   

AeroExpress
-   Max

Es:
-   Rodrigo
-   Actors
-   Backend as a service, Content Management System

---
class: middle, center, inverse
# .red[Thanks] for your attention!

???

-   That's all from me, Thank you ...
-   I hope it was interesting and you'll find a helpful tools in this gem. 

---
# Links

-   concurrent-ruby: <http://concurrent-ruby.com>
    -   API doc: <http://ruby-concurrency.github.io/concurrent-ruby>
-   Gitter: <https://gitter.im/ruby-concurrency/concurrent-ruby> 
    -   IRC bridge: <https://irc.gitter.im/>

**Projects**

-   Dynflow: <https://github.com/dynflow/dynflow>    
-   Foreman: <http://theforeman.org/>    
-   Katello: <https://github.com/Katello/katello/>
-   Staypuft: <https://github.com/theforeman/staypuft>

**Me**

-   Twitter: [@pitr_ch](https://twitter.com/pitr_ch)
-   Github: <http://github.com/pitr-ch>

???

-   Find me on Gitter if you have any questions later.
-   You can follow me on twitter, I'll by posting any interesting news about concurrent-ruby.
