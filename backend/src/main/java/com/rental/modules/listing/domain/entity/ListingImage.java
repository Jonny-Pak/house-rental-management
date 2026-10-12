package com.rental.modules.listing.domain.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "listing_images")
public class ListingImage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "image_id")
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "listing_id", nullable = false)
    private Listing listing;
    @Column(name = "image_url", nullable = false, length = 255)
    private String imageUrl;
    @Column(name = "is_thumbnail")
    private boolean thumbnail;
    @Column(name = "sort_order")
    private short sortOrder;

    public ListingImage() {}
    public ListingImage(Listing listing, String imageUrl, int index) {
        this.listing = listing;
        this.imageUrl = imageUrl;
        this.thumbnail = index == 0;
        this.sortOrder = (short) index;
    }
    public String getImageUrl() { return imageUrl; }
}
