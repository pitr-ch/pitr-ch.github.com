class: center, inverse, middle

# Concurrent .red[Ruby]

### Petr Chalupa

---
# Content

-   Motivation
-   What is (not) concurrent-ruby?
-   What's there?
-   Challenges in .red[Ruby] world
-   Examples

???

-   *TODO*
-   design goals
-   what we have

---
class: center, inverse, middle

# Motivation

---
# Current State

<table>
  <tr><td class="align-right">CRuby has <strong>GIL</strong></td><td class="align-left">⟹ .red[✗] parallelism</td></tr>
  <tr><td class="align-right"> JRuby and Rubinius have no .strike[**GIL**] </td><td class="align-left"> ⟹ .green[✓] parallelism </td></tr>
</table>

-   Stdlib: `Thread`, `Queue`, `Mutex`, `Monitor`, `ConditionVariable`.
-   Implementation specific:
    -   `JRuby::Synchronized`
    -   Java interoperation
    -   `Rubinius::Channel`
    -   `Rubinius.lock` etc.

???


-   GVL; Both allow concurrency though
-   All Rubies have stdlib
-   CRuby is still good for IO heavy applications though.
-   -
-   does not help dev. MRI -> depl. JRuby

closure:

-   **Q:** but is it enough and is it easy to do?
-   Concurrency is hard.

---
# Problems

-   Only stdlib tools are not enough.
-   Memory consumption when forking (unavailable on JRuby).


???

*TODO* live lock keep?
*TODO* more problems

---
class: center, inverse, middle

# What is (not) .red[concurrent-ruby]?

---
# What is not .red[concurrent-ruby]?

-   New ruby implementation
-   Extension of the language itself
-   Opinionated
-   Dependent on `ActiveSupport`
-   One man's effort
-   Implementation specific
-   *TODO*

---
# What is .red[concurrent-ruby]?

-   Gem
-   Library
-   MIT-licensed
-   CRuby, JRuby, and Rubinius support
-   Toolbox
    -   Low level abstractions
    -   High level abstractions
-   Active community
    -   over 1K Github stars
    -   26 contributors

???

-   J: 1K people may just want to return back and read it

---

.center[
.avatar[![jdantonio.jpeg](images/avatars/jdantonio.jpeg)]
.avatar[![pitr-ch.jpeg](images/avatars/pitr-ch.jpeg)]
.avatar[![mighe.jpeg](images/avatars/mighe.jpeg)]
.avatar[![chrisseaton.jpeg](images/avatars/chrisseaton.jpeg)]
.avatar[![rkday.jpeg](images/avatars/rkday.jpeg)]
.avatar[![obrok.jpeg](images/avatars/obrok.jpeg)]
.avatar[![adamruzicka.jpeg](images/avatars/adamruzicka.jpeg)]

.avatar[![billdueber.jpeg](images/avatars/billdueber.jpeg)]
.avatar[![lucasallan.jpeg](images/avatars/lucasallan.jpeg)]
.avatar[![mastfish.jpeg](images/avatars/mastfish.jpeg)]
.avatar[![rrrene.jpeg](images/avatars/rrrene.jpeg)]
.avatar[![brainopia.jpeg](images/avatars/brainopia.jpeg)]
.avatar[![brixen.jpeg](images/avatars/brixen.jpeg)]
.avatar[![alexdowad.jpeg](images/avatars/alexdowad.jpeg)]

.avatar[![larrylv.jpeg](images/avatars/larrylv.jpeg)]
.avatar[![ShaneWilton.jpeg](images/avatars/ShaneWilton.jpeg)]
.avatar[![jrochkind.jpeg](images/avatars/jrochkind.jpeg)]
.avatar[![alexfalkowski.jpeg](images/avatars/alexfalkowski.jpeg)]
.avatar[![gmalkas.jpeg](images/avatars/gmalkas.jpeg)]
.avatar[![gcapizzi.jpeg](images/avatars/gcapizzi.jpeg)]
.avatar[![GrooveStomp.jpeg](images/avatars/GrooveStomp.jpeg)]

.avatar[![jirutka.jpeg](images/avatars/jirutka.jpeg)]
.avatar[![jamiehodge.jpeg](images/avatars/jamiehodge.jpeg)]
.avatar[![joshk.jpeg](images/avatars/joshk.jpeg)]
.avatar[![sheaney.jpeg](images/avatars/sheaney.jpeg)]
.avatar[![zph.jpeg](images/avatars/zph.jpeg)]

# Thanks!
]

???

*TODO add names*?
.small[jdantonio pitr-ch mighe chrisseaton rkday obrok adamruzicka billdueber
lucasallan mastfish rrrene brainopia brixen alexdowad larrylv ShaneWilton jrochkind alexfalkowski
gmalkas gcapizzi GrooveStomp jirutka jamiehodge joshk sheaney zph]

---
class: center, inverse, middle

# What's there?

---
# Low-level constructs

-   Atomics:
    -   AtomicInteger - Java, C
    -   AtomicBoolean - Java, C
    -   Atomic (former `atomic` gem) - Java, C, Rubinius
-   Synchronization primitives:
    -   CountDownLatch - Java
    -   Event
    -   Condition
    -   Semaphore - Java
-   ThreadLocalVar - Java
-   IVar
-   MVar ➤ Exchanger
-   Delay ➤ LazyRegister

---
# High-level abstracts

-   Async
-   TimerTask
-   Future
-   Promise
-   Executors - Java
-   Channel
-   Agent
-   Actor
-   TVar (STM)

???

-   go over them quickly!

---
class: center, inverse, middle

# .red[Ruby] World Challenges

???

*TODO*

-   Ruby world challenges
    -   Native C extensions
    -   synchronization - 3(+1) implementations
    -   final instances in objects for lock free algorithms
    -   atomic instance variable read
    -   creating mutex in JRuby
    -   GC start support - thread local variable
    -   investigate native ThreadPools


---
# Native extensions (1/2)

.center[
<table>
  <tr><td class="align-right"> Java extensions and .red[JRuby]</td><td class="align-left"> ⟹ just works</td></tr>
  <tr><td class="align-right"> C extensions and .red[CRuby]</td><td class="align-left">⟹ .purple[**`@glitches`**]</td></tr>
</table>
]

--

### .purple[**`@glitches`**]:

-   Compilation tools may not be available
-   Compilation may fail
-   No fallback to pure Ruby implementation

---
# Native extensions (2/2)

Companion gem `concurrent-ruby-ext` since v0.8.

-   Adds precompiled C extensions.
-   or they are compiled on installation.
-   It is never a dependency of a gem.
-   Just `gem 'concurrent-ruby-ext'` in `Gemfile`.
    -   Same versioning.

???

*TODO precompiled only for java and win32*

---
# Forcing GC to run

How to test `ThreadLocalVar` using weak references?

-   **CRuby** - builtin support `GC.start`
-   **Rubinius** - `GC.start` may be ignored, use `GC.run(true)`
-   **JRUby** - not supported
    -   maybe function `ForceGarbageCollection` in JVMTI through JNI

???

source: http://sleeplessinslc.blogspot.cz/2008/12/jvmti-jni-absolute-power.html

---
class: center, inverse, middle

# Synchronization

--

### .red[with warning]

???

*TODO warn before going too deep*
-   don't do it
-   if you must do it, don't share data across threads
-   if you must share data across threads, don't share mutable state
-   if you must share mutable data across threads, synchronize access to that data

**Danger**
-   warn that it is not 100% sure
-   no documentations or specs from Ruby implementers, mostly source digging
-   if ever verified and released, `concurrent-ruby` will be locked against
    verified Ruby implementations and its versions

# Resources

-   Ruby
    https://github.com/ruby/ruby/blob/1ea49760417b17e62a90cce3d736f777cbfd52b7/thread_pthread.c#L101-L107
    https://github.com/ruby/ruby/blob/1ea49760417b17e62a90cce3d736f777cbfd52b7/thread_pthread.c#L203-L211
    http://pubs.opengroup.org/onlinepubs/007908799/xsh/pthread_mutex_lock.html
-   Rubinius
    https://github.com/rubinius/rubinius/blob/4e05ddc92b69358040f35a486d8f213dce66ce75/kernel/bootstrap/rubinius.rb#L133-L136
    https://github.com/rubinius/rubinius/blob/96f8edaa9530297303a520c6f961ee85c8c66ebc/vm/builtin/system.cpp#L1659-L1662
    https://github.com/rubinius/rubinius/blob/d7e914981ffab77abd4b10516f4ffe76d057de5a/vm/util/atomic.hpp#L62-L72


---
# Primitives (1/3)


Building common synchronization primitives: <br/>
`lock(object)`, `unlock(object)`, `synchronize(object) {}`.

--

-   **CRuby**

    Stdlib: `Mutex`

-   **Rubinius** 

    ```ruby
    Rubinius.synchronize(object) {}
    Rubinius.lock(object)
    Rubinius.unlock(object)
    ```
    
-   **JRuby**

    ```ruby
    java_import org.jruby.util.unsafe.UnsafeHolder
    JRuby.reference0(object).synchronized {}
    UnsafeHolder::U.monitorEnter(JRuby.reference0(object))
    UnsafeHolder::U.monitorExit(JRuby.reference0(object))
    ```


---
# Primitives (2/3) - Why?

-   Performance (JRuby ×1.5)
-   No hidden `@__mutex__` (Rubinius)

Both **JRuby** and **Rubinius** 

-   `local_variable`, `@ivar` access not synchronized.
-   Method calls are not synchronized.

--

```ruby
def initialize
  @mutex = Mutex.new
end

def a_method
  # Broken, @mutex may be nil on some platforms
  @mutex.synchronize { yield }
end  
```

???

-   do benchmarks!

        Rubinius 1M                 user     system      total        real
        Synchronize::Rubinius   4.945972   8.591180  13.537152 ( 10.442984)
        Synchronize::CRuby      6.093426   7.927195  14.020621 ( 10.341888)

        JRuby 10M                  user     system      total        real
        Synchronize::Java     11.810000   0.060000  11.870000 (  5.993000)
        Synchronize::CRuby    16.160000   1.100000  17.260000 (  9.134000)

-   SynchronizedObject implementation go step by step
    -   how to avoid creating mutex in JRuby

---
# Primitives (3/3)

Adding `wait(object, timeout = nil)`, `notify(object)`, `notify_all(object)`

-   **CRuby**

    Stdlib: `ConditionVariable`

-   **Rubinius** 

    Stdlib: `ConditionVariable` or using directly `Rubinius::Channel`

-   **JRuby**

    ```ruby
    JRuby.reference0(object).wait()
    JRuby.reference0(object).notify()
    JRuby.reference0(object).notifyAll()
    ```
???

-   explain Rubinius::Channel

---
# Immutable objects

-   Java final field has guaranteed visibility.
-   Avoids further locks.
-   Actor messages.

```java
class AnObject {
    public final int value;
    public AnObject(int value) { this.value = value; }
}
```

--

`UnsafeHolder::U.store_fence`, `Rubinius.memory_barrier`

```ruby
class Immutable
  attr_reader :val
  def initialize(val)
    @val = val
    freeze
    Rubinius.memory_barrier
  end
end
```

???

-   if constructed properly.

---
# Improving the situation

-   Memory models.
-   Common semantics.

```ruby
attr_final :val1
attr_volatile :val2
```

*TODO*

---
class: center, inverse, middle
# Examples

---

*TODO which abstractions should I pick?*

---
class: center, inverse, middle

# Glimpse of Future

---
*TODO*

-   Future
    -   Synchronization primitives
    -   Integration (Actors, Promises)
    -   stabilization
    -   documentation
    -   tests and sleeps do not work
    -   before 1.0




