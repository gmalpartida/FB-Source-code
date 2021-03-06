package {
    import asunit.errors.AssertionFailedError;
    import asunit.errors.ClassNotFoundError;
    import asunit.errors.InstanceNotFoundError;
    import asunit.errors.UnimplementedFeatureError;
    import asunit.framework.Assert;
    import asunit.framework.AsynchronousTestCase;
    import asunit.framework.AsynchronousTestCaseExample;
    import asunit.framework.AsyncOperation;
    import asunit.framework.RemotingTestCase;
    import asunit.framework.Test;
    import asunit.framework.TestCase;
    import asunit.framework.TestCaseExample;
    import asunit.framework.TestFailure;
    import asunit.framework.TestListener;
    import asunit.framework.TestMethod;
    import asunit.framework.TestResult;
    import asunit.framework.TestSuite;
    import asunit.runner.BaseTestRunner;
    import asunit.runner.TestSuiteLoader;
    import asunit.runner.Version;
    import asunit.textui.AirRunner;
    import asunit.textui.FlexRunner;
    import asunit.textui.FlexTestRunner;
    import asunit.textui.ResultPrinter;
    import asunit.textui.TestRunner;
    import asunit.textui.XMLResultPrinter;
    import asunit.util.ArrayIterator;
    import asunit.util.Iterator;
    import asunit.util.Properties;

    public class AsUnit {
        private var assertionFailedError:AssertionFailedError;
        private var classNotFoundError:ClassNotFoundError;
        private var instanceNotFoundError:InstanceNotFoundError;
        private var unimplementedFeatureError:UnimplementedFeatureError;
        private var assert:Assert;
        private var asynchronousTestCase:AsynchronousTestCase;
        private var asynchronousTestCaseExample:AsynchronousTestCaseExample;
        private var asyncOperation:AsyncOperation;
        private var remotingTestCase:RemotingTestCase;
        private var test:Test;
        private var testCase:TestCase;
        private var testCaseExample:TestCaseExample;
        private var testFailure:TestFailure;
        private var testListener:TestListener;
        private var testMethod:TestMethod;
        private var testResult:TestResult;
        private var testSuite:TestSuite;
        private var baseTestRunner:BaseTestRunner;
        private var testSuiteLoader:TestSuiteLoader;
        private var version:Version;
        private var airRunner:AirRunner;
        private var flexRunner:FlexRunner;
        private var flexTestRunner:FlexTestRunner;
        private var resultPrinter:ResultPrinter;
        private var testRunner:TestRunner;
        private var xMLResultPrinter:XMLResultPrinter;
        private var arrayIterator:ArrayIterator;
        private var iterator:Iterator;
        private var properties:Properties;
        private var asUnit:AsUnit;
    }
}