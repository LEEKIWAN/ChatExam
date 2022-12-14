//
//  ViewController.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit
import DifferenceKit
import ChatLayout

class ViewController: UIViewController {
    var isBeforeLodable = true
    
    static let sectionDateFormat = "yyyy MMM dd, EEEE"
    let dateFormatter = DateFormatter()
    
    let chatLayout = CollectionViewChatLayout()

    
    private var oldSections: [Section] = []
    
    var sections: [Section] = [] {
        didSet {
            oldSections = oldValue
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = ViewController.sectionDateFormat
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        configureCollectionView()
        
        loadInitMessage()
    }


    func configureCollectionView() {
        collectionView.isPrefetchingEnabled = false
        collectionView.alwaysBounceVertical = true
        collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.delegate = self

        collectionView.collectionViewLayout = chatLayout
        
        collectionView.register(UINib(nibName: "MyBubbleCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "MyBubbleCollectionViewCell")
        collectionView.register(UINib(nibName: "OthersBubbleCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "OthersBubbleCollectionViewCell")
  
        collectionView.register(UINib(nibName: "ChattingDateSectionHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ChattingDateSectionHeaderView")
    }
    
    func loadInitMessage() {
        if let jsonData = FileManager.readLocalFile(fileName: "first", extensionType: "json") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .formatted(.iso8601Full)
            guard let decodedMessageList = try? jsonDecoder.decode(ChattingMessageList.self, from: jsonData) else { return }
            guard let messages = decodedMessageList.messageList else { return }
            loadInitialMessages(messages)
        }
    }
    
    func loadBeforeMessage() {
        if let jsonData = FileManager.readLocalFile(fileName: "before", extensionType: "json") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .formatted(.iso8601Full)
            guard let decodedMessageList = try? jsonDecoder.decode(ChattingMessageList.self, from: jsonData) else { return }
            guard let messages = decodedMessageList.messageList else { return }
            insertBeforeMessages(messages)
        }
    }
    
    func loadInitialMessages(_ messageList: [RawMessage]) {
        var changedData = sections
                
        for message in messageList {
            let dateText = message.sentDt?.utcToDeviceLocal(format: ViewController.sectionDateFormat) ?? ""
            let date = dateFormatter.date(from: dateText) ?? Date()

            if let t = changedData.firstIndex(where: { $0.dateText == dateText }) {
                changedData[t].cells.append(message)
            } else {
                let section = Section(dateText: dateText, date: date, cells: [message])
                changedData.append(section)
            }
        }
        
        processUpdates(with: changedData, animated: false) {
//            self.collectionView.scrollToLast(animated: false)
        }
    }
    
    func insertBeforeMessages(_ messageList: [RawMessage]) {
        var changedData = sections
        
        let sortedMessageList = messageList.sorted {
            ($0.sentDt ?? Date()) > ($1.sentDt ?? Date())
        }

        for message in sortedMessageList {
            let dateText = message.sentDt?.utcToDeviceLocal(format: ViewController.sectionDateFormat) ?? ""
            let date = dateFormatter.date(from: dateText) ?? Date()


            if let t = changedData.firstIndex(where: { $0.dateText == dateText }) {
                changedData[t].cells.insert(message, at: 0)
            } else {
                let section = Section(dateText: dateText, date: date, cells: [message])
                changedData.insert(section, at: 0)
            }
        }
        
        processUpdates(with: changedData)
    }
    
    
    
    private func processUpdates(with sections: [Section], animated: Bool = true, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            self.sections = sections
            return
        }

                
        func process() {
            let changeSet = StagedChangeset(source: self.sections, target: sections).flattenIfPossible()
            
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                                      guard changeSet.sectionInserted.isEmpty else {
                                          return true
                                      }
                                      return false
                                  },
                                  onInterruptedReload: {
                                      let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                                      self.collectionView.reloadData()
                                      
                                      self.chatLayout.restoreContentOffset(with: positionSnapshot)
                                  },
                                  completion: { _ in
                                      DispatchQueue.main.async {
                                          completion?()
                                      }
                                  },
                                  setData: { data in
                                      print("df")
                                      self.sections = data
                                  })
        }

        if animated {
            process()
        } else {
            UIView.performWithoutAnimation {
                process()
            }
        }
    }
    
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].cells.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = sections[indexPath.section].cells[indexPath.item]
        
        if indexPath.row % 2 == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyBubbleCollectionViewCell", for: indexPath) as? MyBubbleCollectionViewCell else { return UICollectionViewCell() }

            cell.dateLabel.text = message.sentDt?.utcToDeviceLocal(format: "hh:mm")
            cell.textView.text = message.textMessage?.contents ?? message.linkMessage?.contents ?? "it's not Message\n\n\n\n\\nn\nn\n\n\n\nit's Image"
            
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OthersBubbleCollectionViewCell", for: indexPath) as? OthersBubbleCollectionViewCell else { return UICollectionViewCell() }

            cell.dateLabel.text = message.sentDt?.utcToDeviceLocal(format: "hh:mm")
            cell.textView.text = message.textMessage?.contents ?? message.linkMessage?.contents ?? "it's not Message \n\n\n\n\n\n\n\n\n\n\n\n\n\n\nnnit's Image"
            
            
            return cell
        }
        
                
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ChattingDateSectionHeaderView", for: indexPath) as? ChattingDateSectionHeaderView else { return UICollectionReusableView() }
            headerView.date = sections[indexPath.section].date
            return headerView
        default:
            assert(false, "아이냐")
            return UICollectionReusableView()
        }
    }
    
}


extension ViewController: ChatLayoutDelegate {
    func shouldPresentHeader(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        return true
    }
}




extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isBeforeLodable == false { return }
        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
            isBeforeLodable.toggle()
            loadBeforeMessage()
            
        }
    }
}
