import Foundation
import foundationKit
import businessKit
import ObjectiveC

struct RuntimeDuplicateTest {

    struct TestResult {
        let testName: String
        let passed: Bool
        let detail: String
    }

    // Test 1: Two separate ObjC root class hierarchies
    static func testSeparateClassHierarchies() -> TestResult {
        // K/N generates a root base class per framework: <FrameworkName>Base
        let foundationBase: AnyClass? = NSClassFromString("FoundationKitBase")
        let businessBase: AnyClass? = NSClassFromString("BusinessKitBase")

        let detail: String
        let passed: Bool

        if let fb = foundationBase, let bb = businessBase {
            let sameClass = fb === bb
            passed = !sameClass
            detail = """
            FoundationKitBase ptr: \(Unmanaged.passUnretained(fb as AnyObject).toOpaque())
            BusinessKitBase ptr:   \(Unmanaged.passUnretained(bb as AnyObject).toOpaque())
            Same class? \(sameClass)
            """
        } else {
            passed = false
            detail = "Could not find base classes. Foundation: \(foundationBase != nil), Business: \(businessBase != nil)"
        }

        return TestResult(testName: "Separate ObjC Class Hierarchies", passed: passed, detail: detail)
    }

    // Test 2: dladdr shows symbols come from different dynamic library images
    static func testDifferentDylibImages() -> TestResult {
        var foundationInfo = dl_info()
        var businessInfo = dl_info()

        // Get class meta-object pointers for known classes from each framework
        let foundationCls: AnyClass? = NSClassFromString("FoundationKitPlatform_iosKt")
            ?? NSClassFromString("FoundationKitSharedData")
            ?? NSClassFromString("FoundationKitBase")
        let businessCls: AnyClass? = NSClassFromString("BusinessKitUserService")
            ?? NSClassFromString("BusinessKitSharedDataProcessor")
            ?? NSClassFromString("BusinessKitBase")

        guard let fCls = foundationCls, let bCls = businessCls else {
            return TestResult(
                testName: "Different Dylib Images",
                passed: false,
                detail: "Could not resolve classes. Foundation: \(foundationCls != nil), Business: \(businessCls != nil)"
            )
        }

        let fPtr = unsafeBitCast(fCls, to: UnsafeRawPointer.self)
        let bPtr = unsafeBitCast(bCls, to: UnsafeRawPointer.self)

        let fResult = dladdr(fPtr, &foundationInfo)
        let bResult = dladdr(bPtr, &businessInfo)

        let fImage = fResult != 0 ? String(cString: foundationInfo.dli_fname) : "unknown"
        let bImage = bResult != 0 ? String(cString: businessInfo.dli_fname) : "unknown"

        let fShort = (fImage as NSString).lastPathComponent
        let bShort = (bImage as NSString).lastPathComponent

        let differentImages = fImage != bImage

        let detail = """
        Foundation image: \(fShort)
        Business image:   \(bShort)
        Different images: \(differentImages)
        """

        return TestResult(testName: "Different Dylib Images", passed: differentImages, detail: detail)
    }

    // Test 3: Enumerate all ObjC classes with framework prefixes
    static func testDuplicateObjCClasses() -> TestResult {
        var classCount: UInt32 = 0
        let classListPtr = objc_copyClassList(&classCount)
        guard let classListPtr = classListPtr else {
            return TestResult(testName: "ObjC Class Enumeration", passed: false, detail: "Failed to get class list")
        }
        defer { free(UnsafeMutableRawPointer(classListPtr)) }

        var foundationClasses: [String] = []
        var businessClasses: [String] = []
        var kotlinClasses: [String] = []

        // AutoreleasingUnsafeMutablePointer<AnyClass> 的下标走 swift_dynamicCast，
        // 会在 CocoaPods use_frameworks! 产生的未 realize stub class 上 trap。
        // 用 UnsafeRawPointer.load 直接读指针值，完全绕过 swift_dynamicCast。
        let raw = UnsafeRawPointer(OpaquePointer(classListPtr))
        let stride = MemoryLayout<UnsafeRawPointer>.stride

        for i in 0..<Int(classCount) {
            let clsRaw = raw.load(fromByteOffset: i * stride, as: UnsafeRawPointer.self)
            let cls: AnyClass = unsafeBitCast(clsRaw, to: AnyClass.self)
            let name = String(cString: class_getName(cls))
            if name.hasPrefix("FoundationKit") {
                foundationClasses.append(name)
            } else if name.hasPrefix("BusinessKit") {
                businessClasses.append(name)
            } else if name.hasPrefix("Kotlin") {
                kotlinClasses.append(name)
            }
        }

        let fSorted = foundationClasses.sorted()
        let bSorted = businessClasses.sorted()

        let detail = """
        FoundationKit* classes (\(fSorted.count)):
          \(fSorted.joined(separator: "\n  "))

        BusinessKit* classes (\(bSorted.count)):
          \(bSorted.joined(separator: "\n  "))

        Kotlin* classes (shared prefix, \(kotlinClasses.count)):
          \(kotlinClasses.sorted().prefix(20).joined(separator: "\n  "))
        """

        return TestResult(
            testName: "Duplicate ObjC Classes",
            passed: foundationClasses.count > 3 && businessClasses.count > 3,
            detail: detail
        )
    }

    static func runAll() -> [TestResult] {
        return [
            testSeparateClassHierarchies(),
            testDifferentDylibImages(),
            testDuplicateObjCClasses()
        ]
    }
}
