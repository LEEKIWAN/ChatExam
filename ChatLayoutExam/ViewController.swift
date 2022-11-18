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
    
    let flowLayout = CollectionViewChatLayout()
        
    typealias Section = ArraySection<ChattingDateSection, RawMessage>

    var data: [Section] = []

    var dataInput: [Section] {
        get { return data }
        set {
            let changeSet = StagedChangeset(source: data, target: newValue).flattenIfPossible()
            
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                                      guard changeSet.sectionInserted.isEmpty else {
                                          return true
                                      }
                                      return false
                                  },
//                                  onInterruptedReload: { [weak self] in
//                                      let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 3, section: 0), kind: .footer, edge: .bottom)
//                                      self?.collectionView.reloadData()
//
//                                      self?.flowLayout.restoreContentOffset(with: positionSnapshot)
//                                  },
                                  completion: { _ in
                                      DispatchQueue.main.async {
//                                          self.collectionView.scrollToItem(at: IndexPath(row: 6, section: 1), at: .centeredVertically, animated: true)
                                      }
                                  },
                                  setData: { [weak self] data in
                                      self?.data = data
                                  })
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

        flowLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        flowLayout.delegate = self

        collectionView.collectionViewLayout = flowLayout
        
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
        var changedData = dataInput
                
        for message in messageList {
            let dateText = message.sentDt?.utcToDeviceLocal(format: ViewController.sectionDateFormat) ?? ""
            let date = dateFormatter.date(from: dateText) ?? Date()
            
            
            if let t = changedData.firstIndex(where: { $0.model.dateText == dateText }) {
                changedData[t].elements.append(message)
            } else {
                let sectionModel = ChattingDateSection(dateText: dateText, date: date)
                let section = Section(model: sectionModel, elements: [message])

                changedData.append(section)
            }
        }
        
        UIView.performWithoutAnimation {
            dataInput = changedData
        }
        
//        collectionView.scrollToLast(animated: false)
    }
    
    func insertBeforeMessages(_ messageList: [RawMessage]) {
        var changedData = dataInput
        
        let sortedMessageList = messageList.sorted {
            ($0.sentDt ?? Date()) > ($1.sentDt ?? Date())
        }
        
        for message in sortedMessageList {
            let dateText = message.sentDt?.utcToDeviceLocal(format: ViewController.sectionDateFormat) ?? ""
            let date = dateFormatter.date(from: dateText) ?? Date()
            
            
            if let t = changedData.firstIndex(where: { $0.model.dateText == dateText }) {
                changedData[t].elements.insert(message, at: 0)
            } else {
                let sectionModel = ChattingDateSection(dateText: dateText, date: date)
                let section = Section(model: sectionModel, elements: [message])

                changedData.insert(section, at: 0)
            }
        }
        
        UIView.performWithoutAnimation {
            dataInput = changedData
        }
    }
    
    
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].elements.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = data[indexPath.section].elements[indexPath.row]
        
        if indexPath.row % 2 == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyBubbleCollectionViewCell", for: indexPath) as? MyBubbleCollectionViewCell else { return UICollectionViewCell() }

            cell.dateLabel.text = message.sentDt?.utcToDeviceLocal(format: "hh:mm")
            cell.textView.text = message.textMessage?.contents ?? message.linkMessage?.contents ?? "it's not Message\n\n\n\n\\nn\nn\n\n\n\nit's Image"
            
            cell.textView.sizeToFit()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OthersBubbleCollectionViewCell", for: indexPath) as? OthersBubbleCollectionViewCell else { return UICollectionViewCell() }

            cell.dateLabel.text = message.sentDt?.utcToDeviceLocal(format: "hh:mm")
            cell.textView.text = message.textMessage?.contents ?? message.linkMessage?.contents ?? "it's not Message \n\n\n\n\n\n\n\n\n\n\n\n\n\n\nnnit's Image"
            
            cell.textView.sizeToFit()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            
            
            
            return cell
        }
        
                
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ChattingDateSectionHeaderView", for: indexPath) as? ChattingDateSectionHeaderView else { return UICollectionReusableView() }
            headerView.date = data[indexPath.section].model.date
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
