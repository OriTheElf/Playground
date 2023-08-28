//
//  RunLoopObserver.swift
//  KnowLED
//
//  Created by Choi on 2023/8/28.
//

import UIKit

final class RunLoopObserver {
    
    private(set) var tasks: [SimpleCallback] = .empty
    
    init() {
        addRunLoopObServer()
    }
    
    func removeAllTask() {
        tasks.removeAll()
    }
    
    func append(task: @escaping SimpleCallback) {
        tasks.append(task)
    }
    
    fileprivate func addRunLoopObServer() {
        do {
            let block: (CFRunLoopObserver?, CFRunLoopActivity) -> Void = {
                [unowned self] ob, ac in
                if ac == .entry {
                    // print("进入 Runloop")
                } else if ac == .beforeTimers {
                    // print("即将处理 Timer 事件")
                } else if ac == .beforeSources {
                    // print("即将处理 Source 事件")
                    if tasks.isNotEmpty {
                        let task = tasks.removeFirst()
                        task()
                    }
                } else if ac == .beforeWaiting {
                    // print("Runloop 即将休眠")
                } else if ac == .afterWaiting {
                    // print("Runloop 被唤醒")
                } else if ac == .exit {
                    // print("退出 Runloop")
                }
            }
            let ob = try createRunloopObserver(block: block)
            
            /// - Parameter rl: 要监听的 Runloop
            /// - Parameter observer: Runloop 观察者
            /// - Parameter mode: 要监听的 mode
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), ob, .defaultMode)
        } catch {
            dprint("无法创建")
        }
    }
    
    fileprivate func createRunloopObserver(block: @escaping (CFRunLoopObserver?, CFRunLoopActivity) -> Void) throws -> CFRunLoopObserver {
        
        /*
         *
         allocator: 分配空间给新的对象。默认情况下使用NULL或者kCFAllocatorDefault。
         
         activities: 设置Runloop的运行阶段的标志，当运行到此阶段时，CFRunLoopObserver会被调用。
         
         public struct CFRunLoopActivity : OptionSet {
         public init(rawValue: CFOptionFlags)
         public static var entry             //进入工作
         public static var beforeTimers      //即将处理Timers事件
         public static var beforeSources     //即将处理Source事件
         public static var beforeWaiting     //即将休眠
         public static var afterWaiting      //被唤醒
         public static var exit              //退出RunLoop
         public static var allActivities     //监听所有事件
         }
         
         repeats: CFRunLoopObserver是否循环调用
         
         order: CFRunLoopObserver的优先级，正常情况下使用0。
         
         block: 这个block有两个参数：observer：正在运行的run loop observe。activity：runloop当前的运行阶段。返回值：新的CFRunLoopObserver对象。
         */
        let ob = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, block)
        guard let observer = ob else {
            throw "无法创建"
        }
        return observer
    }
}
