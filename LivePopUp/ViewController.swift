//
//  ViewController.swift
//  LivePopUp
//
//  Created by LeeHsss on 2022/01/27.
//

import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics

class ViewController: UIViewController {
    
    var remoteConfig: RemoteConfig?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteConfig = RemoteConfig.remoteConfig()
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        // 테스트를 위해 새로운 값을 패치하는 인터벌을 최소화해서 최대한 자주 원격 구성의 데이터를 가져오게끔
        
        remoteConfig?.configSettings = setting
        
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getNotice()
    }
}

//MARK: RemoteConfig
extension ViewController {
    func getNotice() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch { [weak self] status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)
            } else {
                print("ERROR: Config not fetched")
            }
            
            guard let self = self else { return }
            
            if !self.isNoticeHidden(remoteConfig) {
                let noticeVC = NoticeViewController(nibName: "NoticeViewController", bundle: nil)
                noticeVC.modalPresentationStyle = .custom
                noticeVC.modalTransitionStyle = .crossDissolve
                
                let title = (remoteConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let detail = (remoteConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let date = (remoteConfig["date"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                
                noticeVC.noticeContents = (title: title, detail: detail, date: date)
                
                self.present(noticeVC, animated: true, completion: nil)
            } else {
                self.showEventAlert()
            }
        }
    }
    
    func isNoticeHidden(_ remoteConfig: RemoteConfig) -> Bool {
        return remoteConfig["isHidden"].boolValue
    }
}

//MARK: A/B Test
extension ViewController {
    func showEventAlert() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch { [weak self] status, _ in
            if status == .success {
                remoteConfig.activate(completion: nil)
            } else {
                print("ERROR: Config not fetched")
            }
        }
        
        let message = remoteConfig["message"].stringValue ?? ""
        
        let confirmAction = UIAlertAction(title: "확인하기", style: .default) { action in
            //MARK: Google Analytics
            Analytics.logEvent("promotion_alert", parameters: nil) // 버튼이 눌릴때마다 이벤트 기록
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        let alertController = UIAlertController(title: "깜짝 이벤트!!", message: message, preferredStyle: .alert)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
