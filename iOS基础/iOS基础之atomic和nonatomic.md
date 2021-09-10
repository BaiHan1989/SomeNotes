### 简介
在 `iOS` 开发中，通常情况下，一个类可能会有多个属性，而用来修饰属性的关键字有很多，我们也会经常遇到下面的面试题：

- `atomic` 和 `nonatomic`都可以用来修饰一个属性，为什么iOS开发中通常用`nonatomic`修饰属性？`atomic`是线程安全的吗（最好结合场景聊聊）？

```
@property (copy) NSString *name;
@property (atomic, copy) NSString *name;
@property (nonatomic, copy) NSString *name;
```
- **以上3行代码有什么区别？**
**答：如果是编译器自动生成getter和setter方法，第1、2行代码没有任何区别（缺省的关键字即`atomic`），第3行代码和前2行代码不同。如果是我们手动实现getter和setter方法，那么这三行代码没有什么区别**

由此，可以得出一个结论，定义属性时候，`atomic`关键字为**默认关键字**。
大家都知道，`atomic`关键字修饰属性的性能要比`nonatomic`关键字修饰属性的性能要低。所以通常在iOS开发中，定义属性使用`nonatomic`。目的就是为了提高性能，节省可怜的资源。然而为什么`atomic`关键字修饰的属性性能会低呢？

首先让我们理解一下原子性这个概念呢：

- atomic：原子性的，在化学界，原子是元素能保持其化学性质的最小单位，最小单位意味着不可再分割。
- 上面的概念运用到计算机领域，可以理解为一系列操作是不可分割的。

```
int a = 10;
int b = 20;
int c = a + b;
```
- 举例来说，上面三行代码，要求他们是不可分割的一部分，同时有多个线程都要进行上面的操作，我们需要对上面三行代码进行加锁操作，来保证只能有一个线程执行此操作。那么就要加锁。加锁操作，就是保证了原子性。

```
加锁操作
int a = 10;
int b = 20;
int c = a + b;
解锁操作
```

回到iOS开发中，当定义一个属性之后，编译器会为自动为我们生成带`_`（下划线）的成员变量以及`getter`和`setter`方法， 如果使用`atomic`修饰属性，那么在编译器为我们生成`setter`和`getter`方法的时候，**对`getter`和`setter`方法内部实现会做加锁的操作**，加锁的目的就是为了**保证存取值的安全性/完整性，也就是说getter和setter方法内部对于值的存取是线程安全的，并不能保证操作这个属性的时候是线程安全的**。参考objc的源码，我们可以找到答案。具体可以查看这个类`objc-accessors.mm`
这个类中有两个函数：
```
id objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, BOOL atomic) {
    if (offset == 0) {
        return object_getClass(self);
    }

    // Retain release world
    id *slot = (id*) ((char*)self + offset);
    if (!atomic) return *slot;
        
    // Atomic retain release world
    spinlock_t& slotlock = PropertyLocks[slot];
    slotlock.lock();
    id value = objc_retain(*slot);
    slotlock.unlock();
    
    // for performance, we (safely) issue the autorelease OUTSIDE of the spinlock.
    return objc_autoreleaseReturnValue(value);
}

```

```
static inline void reallySetProperty(id self, SEL _cmd, id newValue, ptrdiff_t offset, bool atomic, bool copy, bool mutableCopy)
{
    if (offset == 0) {
        object_setClass(self, newValue);
        return;
    }

    id oldValue;
    id *slot = (id*) ((char*)self + offset);

    if (copy) {
        newValue = [newValue copyWithZone:nil];
    } else if (mutableCopy) {
        newValue = [newValue mutableCopyWithZone:nil];
    } else {
        if (*slot == newValue) return;
        newValue = objc_retain(newValue);
    }

    if (!atomic) {
        oldValue = *slot;
        *slot = newValue;
    } else {
        spinlock_t& slotlock = PropertyLocks[slot];
        slotlock.lock();
        oldValue = *slot;
        *slot = newValue;        
        slotlock.unlock();
    }

    objc_release(oldValue);
}
```

- 上面的2个函数，可以看到函数中的形参中包含了一个bool类型的形参，atomic
- 当传入的`atomic`是true的时候，会使用spinlock进行加锁和解锁的操作，同时验证了，使用的是自旋锁进行的加锁操作，自旋锁会一直处于忙等状态而不是休眠，所以也会消耗性能。


场景：
如果使用`atomic`修饰属性值，有A和B两个线程，A线程对属性进行赋值，B线程进行取值操作，当A线程赋值进行一半的时候，由于setter方法内部加锁的缘故，A线程会持有这把锁，当B线程进行取值操作时候，发现A线程持有锁，那么会进行等待，当A线程赋值操作结束后，setter方法内部会放开锁，保证了设置了一个完整的值，那么B线程进行取值操作，getter方法内部持有这把锁，获取到完整的值后，解锁，返回完整的值，最终可以保证B线程一定可以取到一个完整的值。

如果使用`nonatomic`修饰属性值，有A和B两个线程，A线程对属性进行赋值，当A线程赋值进行一半的时候，B线程进行取值操作，由于setter方法内部没有加锁，赋值还没有完成，B线程从getter方法中取不到一个完整的值，拿到一个不完整的值去做一些操作就可能会发生意想不到的事情。

**`atomic`并不能保证线程是安全的，只能保证存取值的完整性**。

场景：
使用`atomic`修饰属性，如果有A、B和C三个线程。其中A和B线程同时对一个属性进行赋值操作，C线程进行取值操作，那么可以保证C线程一定可以取到一个完整的值，但是这个值的内容可能是A线程赋的值，也可能是B线程赋的值，也可能是原始值，虽然取得了完整的值，但是这个值不一定是程序员想要的，所以说`atomic`并不是线程安全的，它只是保证了属性的setter和getter方法内部是线程安全的。如果你想要真正保证线程安全，那么需要在赋值操作的前后进行加锁和解锁操作，还有注意使用同一把锁。

**为什么说`atomic`关键字是消耗性能的？**

因为，`atomic`底层有加锁的操作，上面也提到了是自旋锁，自旋锁会进行忙等，可以理解为一个while循环一直等，性能肯定会比`nonatomic`不加锁低。

在平时开发的时候，不涉及线程安全的时候，比如一些UI控件必须在主线程操作的，用`nonatomic`可以提高性能。而真正要涉及线程安全，不能只靠编译器，需要程序员自己控制。