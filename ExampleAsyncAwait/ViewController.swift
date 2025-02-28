//
//  ViewController.swift
//  ExampleAsyncAwait
//
//  Created by 황재현 on 2/28/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa


class ViewController: UIViewController {
    // 라벨
    let label = UILabel().then {
        $0.tintColor = .blue
        $0.textAlignment = .center
    }
    // 버튼
    let button = UIButton().then {
        $0.backgroundColor = .red
        $0.setTitle("버튼", for: .normal)
        $0.layer.cornerRadius = 8
    }
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        binding()
    }
    
    
    func configureUI() {
        print("configureUI()")
        
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalTo(view.center)
            make.width.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(16)
            make.leading.trailing.equalTo(label)
            make.width.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
    }
    
    func binding() {
        button.rx.tap.subscribe { [weak self] tap in
            guard let self = self else { return }
            print("tap")
            
//            self.getNumberData(a: 10, b: 6)
//            self.getUserAndPost()
//            self.getErrorData()
            
            Task {
                await self.fetchMutipleData()
            }
            
        }.disposed(by: disposeBag)
    }
    
    
    // MARK: -- Method
    func getNumberData(a: Int, b: Int) {
        Task {
            // await = 비동기 함수가 끝날 때까지 기다림
            let plus = await plusData(a: a, b: b)
            print("plus = \(plus)")
            let minus = await minusData(a: a, b: b)
            print("minus = \(minus)")
            
            let multiply = await multiplyData(a: plus, b: minus)
            print("multiply = \(multiply)")
            
            await updateUI(data: multiply)
        }
    }
    
    /*
     let user = await timeUser() => 2초 후 실행
     let post = await timePost() => await timeUser()가 끝난 후 3초 후 실행
     -> 2초 + 3초 = 5초 후 실행
     */
    func getUserAndPost() {
        Task {
            let user = await timeUser()
            let post = await timePost()
            
            print("user = \(user), post = \(post)")
        }
    }
    
    /*
     MARK: - async let = 여러개의 비동기 함수를 동시에 실행할 수 있음
     async let user = timeUser(), async let posts = timePost() 동시에 실행
     let userData = await user => 2초 후 실행
     let postsData = await posts => 3초 후 실행
     -> 2초, 3초 => 3초 후 실행
     
     Task {
        await getAsyncLetUserAndPost()
     }
     */
    func getAsyncLetUserAndPost() {
        print("taskData()")
        Task {
            async let user = timeUser()
            async let posts = timePost()
            
            let userData = await user
            let postsData = await posts
            
            // user - 2초, post - 3초 = 늦게받는걸로 받아짐 (3초 후 받아짐)
            print(userData, postsData)
        }
    }
    
    // 에러일 수 있는 데이터 가져옴
    func getErrorData() {
        Task {
            do {
                let result = try await getData()
                print("result = \(result)")
            } catch {
                print("error = \(error)")
            }
        }
    }
    
    /*
     MARK: - async = 비동기 메소드를 나타냄
     */
    func fetchData() async -> String {
        return "Test_fetchData()"
    }
    
    func plusData(a: Int, b: Int) async -> Int {
        return a + b
    }
    
    func minusData(a: Int, b: Int) async -> Int {
        return a - b
    }
    
    func multiplyData(a: Int, b: Int) async -> Int {
        return a * b
    }
    
    // 2초 후 값을 받음
    func timeUser() async -> String {
        await Task.sleep(2 * 1_000_000_000) // 2초 대기
        return "User Data"
    }
    // 3초 후 값을 받음
    func timePost() async -> String {
        await Task.sleep(3 * 1_000_000_000) // 3초 대기
        return "Posts Data"
    }
    
    /*
     MARK: TaskGroup: 병렬 작업 최적화
     await withTaskGroup(of: Type.self) { group in ... } 으로 실행하면
     안에 있는 group.addTask { ... } 개별적인 비동기 작업을 추가 후 순차적으로 실행
     for await을 통해 완료된 작업의 결과를 순차적으로 가져옴
     
     Task {
        await fetchMutipleData()
     }
     */
    func fetchMutipleData() async {
        await withTaskGroup(of: String.self) { group in
            for i in 0..<3 {
                group.addTask {
                    return "Task \(i) 완료"
                }
            }
            
            for await result in group {
                print("fetchMutipleData - result = \(result)")
            }
        }
    }
    
    // 에러까지 받을 수 있는 메소드
    func getData() async throws -> String {
        let flag = Bool.random()
        if flag {
            return "flag is true"
        } else {
            // 에러를 반환
            throw NSError(domain: "flag is false", code: -1, userInfo: nil)
        }
    }
    
    
    /*
     MARK: - @MainActor: 비동기 코드에서 UI를 업데이트할때 메인 스레드에서 실행하도록
     "DispatchQueue.main.async" 대신 "@MainActor"를 쓰면 더 깔끔해짐
     */
    @MainActor
    func updateUI(data: Int) async {
        label.text = "\(data)"
    }
}

