package com.rental.modules.listing.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "hinh_anh_tin_dang")
public class ListingImage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ma_hinh_anh")
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ma_tin_dang", nullable = false)
    private Listing listing;
    @Column(name = "duong_dan_hinh_anh", nullable = false, length = 255)
    private String imageUrl;
    @Column(name = "la_anh_dai_dien")
    private boolean thumbnail;
    @Column(name = "thu_tu_hien_thi")
    private short sortOrder;

    public ListingImage() {}
    public ListingImage(Listing listing, String imageUrl, int index) {
        this.listing = listing;
        this.imageUrl = imageUrl;
        this.thumbnail = index == 0;
        this.sortOrder = (short) index;
    }
    public String getImageUrl() {
        return imageUrl;
    }
}
