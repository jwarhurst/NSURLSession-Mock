import UIKit
import XCTest
import NSURLConnection_Mock

class NSURLConnectionTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        
        NSURLConnection.removeAllMocks()
    }
    
    func testMock_WithMockURL_ShouldReturnMockedData() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let data = "test".dataUsingEncoding(NSUTF8StringEncoding)!
        NSURLConnection.mockEvery(URL, data: data)
        
        // Make a delegate we will inspect at the end of the test
        let delegate = TestDelegate(complete: {
            expectation.fulfill()
        })
        
        // Make the request
        let request = NSURLRequest(URL: URL)
        let connection = NSURLConnection.init(request: request, delegate: delegate)
        XCTAssertNotNil(connection)
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(data, delegate.data)
            XCTAssertNil(delegate.error)
        }
    }
    
    func testMock_WithTwoSingleMocks_ShouldReturnBoth() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock these two URLs
        let URL1 = NSURL(string: "https://www.example.com/1")!
        let data1 = "test1".dataUsingEncoding(NSUTF8StringEncoding)!
        NSURLConnection.mockSingle(URL1, data: data1)
        
        let URL2 = NSURL(string: "https://www.example.com/2")!
        let data2 = "test2".dataUsingEncoding(NSUTF8StringEncoding)!
        NSURLConnection.mockSingle(URL2, data: data2)
        
        // Make a delegate we will inspect at the end of the test
        let delegate2 = TestDelegate(complete: {
            expectation.fulfill()
        })
        
        // Make a delegate that will trigger the second request after the first 
        // one is complete
        let delegate1 = TestDelegate(complete: {
            let request = NSURLRequest(URL: URL2)
            let connection = NSURLConnection.init(request: request, delegate: delegate2)
            XCTAssertNotNil(connection)
        })
        
        // Make the first request
        let request = NSURLRequest(URL: URL1)
        let connection = NSURLConnection.init(request: request, delegate: delegate1)
        XCTAssertNotNil(connection)
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(0.5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(data1, delegate1.data)
            XCTAssertEqual(data2, delegate2.data)
        }
    }
    
    func testMock_WithErrorMock_ShouldReturnError() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let error = NSError(domain: "TestDomain", code: 0, userInfo: nil)
        NSURLConnection.mockEvery(URL, error: error)
        
        // Make a delegate we will inspect at the end of the test
        let delegate = TestDelegate(complete: {
            expectation.fulfill()
        })
        
        // Make the request
        let request = NSURLRequest(URL: URL)
        let connection = NSURLConnection.init(request: request, delegate: delegate)
        XCTAssertNotNil(connection)
        
        // Validate that the mock data was returned
        self.waitForExpectationsWithTimeout(0.5) { timeoutError in
            XCTAssertNil(timeoutError)
            XCTAssertEqual(error, delegate.error)
            XCTAssertNil(delegate.data)
        }
    }
    
    func testMock_WithDelay_ShouldWaitForDelay() {
        let expectation = self.expectationWithDescription("Complete called")
        
        // Tell NSURLConnection to mock this URL
        let URL = NSURL(string: "https://www.example.com/1")!
        let error = NSError(domain: "TestDomain", code: 0, userInfo: nil)
        NSURLConnection.mockEvery(URL, error: error, delay: 1.5)
        
        // Make a delegate we will inspect at the end of the test
        let delegate = TestDelegate(complete: {
            expectation.fulfill()
        })
        
        // Make the request
        let request = NSURLRequest(URL: URL)
        let connection = NSURLConnection.init(request: request, delegate: delegate)
        XCTAssertNotNil(connection)
        
        // Validate that the mock data was returned
        let start = NSDate()
        self.waitForExpectationsWithTimeout(2.5) { timeoutError in
            XCTAssertNil(timeoutError)
            
            let end = NSDate()
            let interval = end.timeIntervalSinceDate(start)
            XCTAssert(interval > 1.0, "This request should have taken longer, it took \(interval)")
        }
    }
}